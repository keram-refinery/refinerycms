
(function (window, $) {

// Source: ~/refinery/scripts/admin/admin.js
    /**
     * Refinery Admin namespace
     *
     * @expose
     * @type {Object}
     */
    refinery.admin = {
        ui: {},

        /**
         * Backend path defined by Refinery::Core.backend_route
         * Default: '/refinery'
         *
         * @expose
         * @type {string}
         */
        backend_path: (function () {
            return '/' + document.location.pathname.split('/')[1];
        }())
    };

// Source: ~/refinery/scripts/admin/form.js
    /**
     * @constructor
     * @class  refinery.admin.Form
     * @extends {refinery.Object}
     * @param {Object=} options
     */
    refinery.Object.create({

        name: 'Form',

        module: 'admin',

        /**
         * Switch locale
         *
         * @param {!jQuery} anchor
         *
         * @return {undefined}
         */
        switch_frontend_locale: function (anchor) {
            var buttons = {},
                url = anchor.attr('href'),
                that = this;

            buttons[t('refinery.admin.form_unsaved_save_and_continue')] = function () {
                var form = that.holder,
                    dialog = $(this),
                    param = url.match(/\?[^\?]+$/)[0];

                $.ajax({
                    url: form.attr('action'),
                    method: form.attr('method'),
                    data: form.serialize(),
                    dataType: 'JSON',
                    success: function (response, status, xhr) {
                        var param_re = /frontend_locale=[\w\-]+/,
                            redirected = xhr.getResponseHeader('X-XHR-Redirected-To');

                        dialog.dialog('close');
                        dialog.dialog('destroy');

                        if (redirected) {
                            /**
                             * This is requried in case that user has defined other locale than default.
                             * In that case this scenario is happen:
                             *
                             * POST /refinery/pages/12 // Save request
                             * 302 Found
                             *
                             * GET /refinery/pages/12/edit?frontend_locale=cs // Ok, redirect after save
                             * 200 OK
                             *
                             * GET /refinery/pages/12/edit?frontend_locale=sk // Locale switch request
                             * 200 OK
                             */
                            if (param_re.test(redirected) && param_re.test(param)) {
                                url = redirected.replace(param_re, param.match(param_re)[0]);
                            } else if (/\?/.test(redirected)) {
                                url = redirected + '&' + param.match(param_re)[0];
                            } else {
                                url = redirected + param;
                            }
                            Turbolinks.visit(url);
                        } else if (status === 'error') {
                            refinery.xhr.success(response, status, xhr, form, true);
                        } else {
                            Turbolinks.visit(url);
                        }
                    }
                });
            };

            buttons[t('refinery.admin.form_unsaved_continue')] = function () {
                $(this).dialog('destroy');
                Turbolinks.visit(url);
            };

            buttons[t('refinery.admin.form_unsaved_cancel')] = function () {
                $(this).dialog('close');
                $(this).dialog('destroy');
            };

            $('<div/>', { html: t('refinery.admin.form_unsaved_html')} ).dialog({
                'resizable': false,
                'height': 140,
                'modal': true,
                'title': t('refinery.admin.form_unsaved_title'),
                'buttons': buttons
            });
        },

        init_pickers: function () {
            var that = this,
                form = that.holder;

            form.find('.image-picker').each(function () {
                var picker = refinery('admin.ImagePicker');
                picker.init($(this));
            });

            form.find('.resource-picker').each(function () {
                var picker = refinery('admin.ResourcePicker');
                picker.init($(this));
            });

            form.on('click', '.locale-picker a', function (e) {
                var a = $(this);
                if (that.initial_values === form.serialize()) {
                    return true;
                }

                e.preventDefault();
                e.stopPropagation();
                that.switch_frontend_locale(a);
                return false;
            });
        },

        init_upload: function () {
            var that = this,
                form = that.holder,
                csrf_param = $('meta[name=csrf-param]').attr('content'),
                file_inputs = form.find('input[type="file"]');

            if (file_inputs.length > 0) {
                form.on('submit', function (event) {
                    event.preventDefault();
                    event.stopPropagation();
                    refinery.spinner.on();

                    /**
                     * when form doesn't have included csrf token aka
                     * embed_authenticity_token_in_remote_forms is false
                     * then include it to hidden input from meta
                     */
                    if (form.find('input[name="' + csrf_param + '"]').length === 0) {
                        $('<input/>', {
                            'name': csrf_param,
                            'type': 'hidden',
                            'value': $('meta[name=csrf-token]').attr('content')
                        }).appendTo(form);
                    }

                    $.ajax(this.action, {
                            'data': form.serializeArray(),
                            'files': file_inputs,
                            'iframe': true,
                            'processData': false
                        }).done(
                        /**
                         * @param {json_response} response
                         * @param {string} status
                         * @param {jQuery.jqXHR} xhr
                         * @return {undefined}
                         */
                        function (response, status, xhr) {
                            form.trigger('ajax:success', [response, status, xhr]);
                        }).always(function () {
                            refinery.spinner.off();
                        });
                });
            }
        },

        init_inputs: function () {
            var that = this,
                form = that.holder,
                submit_btn = form.find('.form-actions .submit-button'),
                submit_btn_val;

            if (submit_btn.length > 0) {
                submit_btn_val = submit_btn.val();
                form.on('change', 'input, select, textarea', function () {
                    if (that.initial_values !== form.serialize() &&
                        submit_btn_val[submit_btn_val.length] !== '!'
                    ) {
                        submit_btn.val(submit_btn_val + ' !');
                    } else {
                        submit_btn.val(submit_btn_val.replace(/ !$/, ''));
                    }
                });
            }
        },

        init_fly_form_actions: function () {
            var that = this,
                $window = $(window),
                holder = that.holder.find('.form-actions'),
                left_buttons = that.holder.find('.form-actions-left');

            function scroll () {
                var window_position = $window.scrollTop() + $window.height(),
                    form_actions_pos = holder.position().top;

                if (window_position < form_actions_pos) {
                    left_buttons.addClass('fly');
                } else {
                    left_buttons.removeClass('fly');
                }
            }

            if (that.holder.find('textarea').length > 0 &&
                holder.length > 0 && left_buttons.length > 0) {

                $window.on('scroll', scroll);
                that.on('destroy', function () {
                    $window.unbind('scroll', scroll);
                });

                scroll();
            }
        },

        /**
         * initialisation
         *
         * @param {!jQuery} holder
         *
         * @return {Object} self
         */
        init: function (holder) {
            var that = this;

            if (that.is('initialisable')) {
                that.is('initialising', true);
                that.attach_holder(holder);
                that.init_pickers();
                that.init_inputs();
                that.init_upload();
                that.initial_values = holder.serialize();
                that.init_fly_form_actions();

                that.is({'initialised': true, 'initialising': false});
                that.trigger('init');
            }

            return that;
        }
    });

    /**
     * Form initialization
     *
     * @expose
     * @param  {jQuery} holder
     * @return {undefined}
     */
    refinery.admin.ui.form = function (holder) {
        holder.find('form').each(function () {
            refinery('admin.Form').init($(this));
        });
    };

// Source: ~/refinery/scripts/admin/form_page_parts.js
    /**
     * @constructor
     * @extends {refinery.Object}
     * @param {Object=} options
     */
    refinery.Object.create({

        name: 'FormPageParts',

        module: 'admin',

        /**
         * Create list of page parts for dialog
         *
         * @return {string} dialog content
         */
        get_dialog_content: function () {
            var content;

            content = '<ul class="records">';

            this.nav.find('a').each(function () {
                var a = $(this),
                    active = !a.parent().hasClass('js-hide');

                content += '<li data-part="' + a.attr('href') + '" ';
                content += 'class="clearfix" >';
                content += '<label class="stripped">';
                content += '<input type="checkbox"' + (active ? ' checked="1"' : '') + '"> ';
                content += a.text();
                content += '</label>';
                content += ' <span class="actions"><span class="icon-small move-icon">';
                content += t('refinery.admin.button_move') + '</span></span>';
                content += '</li>';
            });

            content += '</ul>';

            return content;
        },

        /**
         * Initialize page part dialog and bind events
         *
         * @return {undefined}
         */
        init_configuration_dialog: function () {
            var that = this,
                holder = that.holder,
                nav = that.nav,
                dialog_holder,
                dialog_buttons = {},
                parts_tabs = nav.find('li');

            dialog_holder = $('<div/>', {
                html: that.get_dialog_content()
            });

            function update_parts () {
                var list = [], i, l, active_tab;

                dialog_holder.find('li').each(function (j) {
                    var li = $(this),
                        part = /** @type string */(li.data('part')),
                        active = li.find('input').is(':checked'),
                        tab = nav.find('a[href="' + part + '"]').parent().detach(),
                        panel = $(part);

                    if (active) {
                        tab.removeClass('js-hide');
                        panel.removeClass('js-hide');
                    } else {
                        tab.removeClass('ui-tabs-active ui-state-active');
                        tab.addClass('js-hide');
                        panel.addClass('js-hide');
                    }

                    panel.find('input.part-active').prop('checked', active);
                    panel.find('input.part-position').val(j);
                    list[list.length] = tab;
                });

                for (i = 0, l = list.length; i < l; i++) {
                    nav.append(list[i]);
                }

                if (nav.find('.ui-tabs-active').length === 0) {
                    active_tab = parts_tabs.index(nav.find('li:visible').first());

                    holder.tabs({
                        'active': active_tab
                    });
                }
            }

            dialog_holder.on('change', 'li input', update_parts);

            dialog_holder.find('ul').sortable({
                'stop': update_parts
            });

            dialog_buttons[t('refinery.admin.button_done')] = function () {
                update_parts();
                dialog_holder.dialog('close');
            };

            dialog_holder.dialog({
                'title': t('refinery.admin.form_page_parts_manage'),
                'modal': true,
                'resizable': true,
                'autoOpen': false,
                'width': 400,
                'buttons': dialog_buttons
            });

            holder.on('click', '#page-parts-options', function (e) {
                e.preventDefault();
                dialog_holder.dialog('open');
            });

            that.dialog_holder = dialog_holder;
        },

        /**
         *
         * @return {Object} self
         */
        destroy: function () {
            if (this.is('initialised')) {
                this.nav = null;

                if (this.dialog_holder) {
                    this.dialog_holder.dialog('destroy');
                    this.dialog_holder.off();
                    this.dialog_holder = null;
                }
            }

            return this._destroy();
        },

        /**
         * initialisation
         *
         * @param {!jQuery} holder
         *
         * @return {Object} self
         */
        init: function (holder) {
            if (this.is('initialisable')) {
                this.is('initialising', true);
                this.attach_holder(holder);
                this.nav = holder.find('.ui-tabs-nav');
                this.init_configuration_dialog();
                this.is({'initialised': true, 'initialising': false});
                this.trigger('init');
            }

            return this;
        }
    });

    /**
     * Form initialization
     *
     * @expose
     * @param  {jQuery} holder
     * @return {undefined}
     */
    refinery.admin.ui.formPageParts = function (holder) {
        holder.find('#page-parts').each(function () {
            refinery('admin.FormPageParts').init($(this));
        });
    };

// Source: ~/refinery/scripts/admin/sortable_list.js
    /**
     * Sortable List
     *
     * @expose
     * @todo  refactor that SortableTree constructor and SortableList would be the same
     * @extends {refinery.Object}
     * @param {Object=} options
     * @param {boolean=} is_prototype
     */
    refinery.Object.create({

        /**
         * Configurable options
         *
         * @param {{update_url: ?string, redraw: Boolean, nested_sortable: Object}} options
         */
        objectConstructor: function (options, is_prototype) {
            var that = this;

            refinery.Object.apply(that, arguments);

            if (!is_prototype) {

                /**
                 *
                 * @expose
                 * @param {*} event
                 * @param {*} ui
                 *
                 * @return {undefined}
                 */
                that.options.nested_sortable.stop = function (event, ui) {
                    if (that.options.update_url) {
                        that.update(ui.item);
                    }
                };
            }
        },

        name: 'SortableList',

        module: 'admin',

        /**
         * Configurable options
         *
         * @type {Object}
         */
        options: {

            /**
             * @expose
             * @type {?string}
             */
            update_url: null,

            /**
             * @expose
             * @type {?boolean}
             */
            redraw: true,

            /**
             * @expose
             * @type {{items: string, listType: string, maxLevels: number}}
             */
            nested_sortable: {
                listType: 'ul',
                items: 'li',
                maxLevels: 1
            }
        },

        /**
         * Serialized array of items
         *
         * @type {?Array}
         */
        set: null,

        /**
         * Html content of list holder
         *
         * @type {?string}
         */
        html: null,

        /**
         * Get Item id
         *
         * @param {!jQuery} item
         *
         * @return {?string}
         */
        getId: function (item) {
            if (item.attr('id') && /([0-9]+)$/.test(item.attr('id'))) {
                return item.attr('id').match(/([0-9]+)$/)[1];
            }

            return null;
        },

        /**
         * Update item position on server
         *
         * @expose
         * @param {jQuery} item
         *
         * @return {Object} self
         */
        update: function (item) {
            var that = this,
                list = that.holder,
                set = list.nestedSortable('toArray'),
                post_data = {
                    'item': {
                        'id': that.getId(item),
                        'prev_id': that.getId(item.prev()),
                        'next_id': that.getId(item.next()),
                        'parent_id': that.getId(item.parent().parent())
                    }
                };

            if (!that.is('updating') && JSON.stringify(set) !== JSON.stringify(that.set)) {
                that.is({'updating': true, 'updated': false});
                list.nestedSortable('disable');
                refinery.spinner.on();

                $.post(that.options.update_url, post_data, function (response, status, xhr) {
                    if (status === 'error') {
                        list.html(that.html);
                    } else {
                        that.set = set;
                        that.html = list.html();
                    }

                    refinery.xhr.success(response, status, xhr, list);
                    that.is('updated', true);
                    that.trigger('update');
                }, that.options.redraw ? 'JSON' : 'HTML')
                    .fail(function (response) {
                        list.html(that.html);
                        refinery.xhr.error(response);
                    })
                    .always(function () {
                        refinery.spinner.off();
                        that.is('updating', false);
                        list.nestedSortable('enable');
                    });
            }

            return that;
        },

        destroy: function () {
            this.holder.nestedSortable('destroy');
            this.set = null;

            return this._destroy();
        },

        init: function (holder) {
            if (this.is('initialisable')) {
                this.is('initialising', true);
                holder.nestedSortable(this.options.nested_sortable);
                this.attach_holder(holder);
                this.set = holder.nestedSortable('toArray');
                this.html = holder.html();
                this.is({'initialised': true, 'initialising': false});
                this.trigger('init');
            }

            return this;
        }
    });


    /**
     * Sortable Tree
     *
     * @constructor
     * @expose
     * @extends {refinery.admin.SortableList}
     * @param {Object=} options
     * @param {boolean=} is_prototype
     */
    refinery.Object.create({

        objectConstructor:  function (options, is_prototype) {
            var that = this;

            refinery.Object.apply(that, arguments);

            if (!is_prototype) {

                /**
                 *
                 * @expose
                 * @param {*} event
                 * @param {*} ui
                 *
                 * @return {undefined}
                 */
                that.options.nested_sortable.stop = function (event, ui) {
                    that.update_tree(ui.item);
                    if (that.options.update_url) {
                        that.update(ui.item);
                    }
                };
            }
        },

        objectPrototype: refinery('admin.SortableList', {

            /**
             * @expose
             * @type {{items: string, listType: string, maxLevels: number}}
             */
            nested_sortable: {
                'listType': 'ul',
                'handle': '.move',
                'items': 'li',
                'isAllowed': function (placeholder, placeholderParent, currentItem) {
                    if (placeholderParent) {
                        if (placeholderParent.text() === currentItem.parent().text()) {
                            return false;
                        }
                    }

                    return true;
                },
                'maxLevels': 0
            }
        }, true),

        name: 'SortableTree',

        update_tree: function (item) {
            var ul = item.parent();

            this.holder.find('.toggle').each(function () {
                var elm = $(this);
                if (elm.parent().parent().find('li').length === 0) {
                    elm.removeClass('toggle expanded');
                }
            });

            if (ul.attr('id') !== this.holder.attr('id')) {
                ul.addClass('nested data-loaded');
                ul.parent().find('.icon').first().addClass('toggle expanded');
            }
        }
    });

// Source: ~/refinery/scripts/admin/user_interface.js
    /**
     * @constructor
     * @extends {refinery.Object}
     * @param {Object=} options
     * @return {refinery.admin.UserInterface}
     */
    refinery.Object.create({

        name: 'UserInterface',

        module: 'admin',

        options: {
            /**
             * When Ajax request receive partial without id,
             * content of $(main_content_selector) will be replaced.
             *
             * @expose
             * @type {!string}
             */
            main_content_selector: '#content'
        },

        init_checkboxes: function () {
            this.holder.find('div.checkboxes').each(function () {
                var holder = $(this),
                    chboxs = holder.find('input:checkbox').not('[readonly]');

                if (chboxs.length > 1) {
                    holder.find('.checkboxes-cmd.' +
                            ((chboxs.length === chboxs.filter(':checked').length) ? 'none' : 'all')
                    ).removeClass('hide');
                }
            });

            this.holder.on('click', '.checkboxes-cmd', function (e) {
                e.preventDefault();
                var a = $(this),
                    parent = a.parent(),
                    checkboxes = parent.find('input:checkbox'),
                    checked = a.hasClass('all');

                checkboxes.prop('checked', checked);
                parent.find('.checkboxes-cmd').toggleClass('hide');
            });

        },

        init_collapsible_lists: function () {
            this.holder.find('.collapsible-list').accordion();
            this.holder.find('.collapsible-list').each(function () {
                var list = $(this),
                    options = /** Object */(list.data('ui-accordion-options'));

                list.accordion(options);
            });
        },

        init_sortable: function () {
            this.holder.find('.sortable-list').each(function () {
                var list = $(this),
                    options = list.data('sortable-options');

                if (list.hasClass('records')) {
                    if (list.hasClass('tree')) {
                        refinery('admin.SortableTree', options).init(list);
                    } else {
                        refinery('admin.SortableList', options).init(list);
                    }
                } else {
                    list.sortable(options);
                }
            });
        },

        toggle_tree_branch: function (li) {
            var elm = li.find('.toggle').first(),
                nested = li.find('.nested').first();

            if (elm.hasClass('expanded')) {
                elm.removeClass('expanded');
                nested.slideUp();
            } else {

                if (nested.hasClass('data-loaded')) {
                    elm.addClass('expanded');
                    nested.slideDown();
                } else {
                    li.addClass('loading');
                    nested.load(nested.data('ajax-content'), function () {
                        elm.addClass('expanded');
                        nested.slideDown();
                        li.removeClass('loading');

                        if (nested.hasClass('data-cache')) {
                            nested.addClass('data-loaded');
                        }
                    });
                }
            }
        },

        init_tabs: function () {
            this.holder.find('.ui-tabs').each(function () {
                var elm = $(this),
                    index = elm.find('.ui-tabs-nav .ui-state-active').index();

                elm.tabs({
                    'active': (index > -1 ? index : 0),
                    'activate': function (event, ui) {
                        ui.newPanel.find('input.text, textarea').first().focus();
                    }
                });
            });
        },

        bind_events: function () {
            var that = this,
                holder = that.holder;

            /**
             * Process ajax response
             *
             * @param  {jQuery.event} event
             * @param  {json_response} response
             * @param  {string} status
             * @param  {jQuery.jqXHR} xhr
             * @return {undefined}
             */
            function ajax_success (event, response, status, xhr) {
                var redirected_to = xhr.getResponseHeader('X-XHR-Redirected-To'),
                    replace_target = true,
                    target = event.target;

                if (response.redirect_to) {
                    Turbolinks.visit(response.redirect_to);
                } else {
                    if (redirected_to || target.tagName.toLowerCase() === 'a') {
                        target = holder.find(that.options.main_content_selector);
                        replace_target = false;
                    } else {
                        target = $(target);
                    }

                    that.destroy();
                    refinery.xhr.success(response, status, xhr, target, replace_target);
                    that.trigger('ui:change');
                }
            }

            holder.on('click', '.flash-close', function (e) {
                e.preventDefault();
                $(this).parent().fadeOut();
                return false;
            });

            holder.on('click', '.tree .toggle', function (e) {
                e.preventDefault();
                that.toggle_tree_branch($(this).parents('li:first'));
            });

            holder.on('ajax:success', ajax_success);

            holder.on('ajax:error',
                /**
                 * @param {jQuery.event} event
                 * @param {jQuery.jqXHR} xhr
                 * @param {string} status
                 * @return {undefined}
                 */
                function (event, xhr, status) {
                    refinery.xhr.error(xhr, status);
                });

            holder.find('.ui-selectable').selectable({ 'filter': 'li' });
        },

        init_toggle_hide: function () {
            this.holder.on('click', '.toggle-hide', function () {
                var elm = $(this);
                $(elm.attr('href')).toggleClass('js-hide');
                elm.toggleClass('toggle-on');
            });
        },

        initialize_elements: function () {
            var that = this,
                holder = that.holder,
                ui = refinery.admin.ui,
                fnc;

            that.init_sortable();
            that.init_tabs();
            that.init_checkboxes();
            that.init_collapsible_lists();
            that.init_toggle_hide();

            for (fnc in ui) {
                if (ui.hasOwnProperty(fnc) && typeof ui[fnc] === 'function') {
                    ui[fnc](holder, that);
                }
            }

            holder.find('input.text, textarea').first().focus();
        },

        /**
         * Destroy self and also all refinery, jquery ui instances under holder
         *
         * @return {Object} self
         */
        destroy: function () {
            var holder = this.holder,
                holders;

            if (holder) {
                holders = holder.find('.refinery-instance');

                try {
                    holders.each(function () {
                        var instances = $(this).data('refinery-instances'),
                            instance;

                        for (var i = instances.length - 1; i >= 0; i--) {
                            instance = refinery.Object.instances.get(instances[i]);
                            instance.destroy();
                        }
                    });
                } catch (e) {
                    refinery.log(e);
                    refinery.log(holders);
                }
            }

            return this._destroy();
        },

        init: function (holder) {
            var that = this;

            if (that.is('initialisable')) {
                that.is('initialising', true);
                that.attach_holder(holder);
                that.bind_events();
                that.initialize_elements();
                that.is({'initialised': true, 'initialising': false});
                that.trigger('init');
            }

            return that;
        }
    });

// Source: ~/refinery/scripts/admin/dialogs/dialog.js
   /**
     * refinery Object State
     *
     * @constructor
     * @extends {refinery.ObjectState}
     * @param {Object=} default_states
     *    Usage:
     *        new refinery.ObjectState();
     *
     * @todo  measure perf and if needed refactor to use bit masks, fsm or something else
     */
    function DialogState (default_states) {
        var states = $.extend(default_states || {}, {
            'closed' : true
        });

        refinery.ObjectState.call(this, states);
    }

    /**
     * Custom State Object prototype
     * @expose
     * @type {Object}
     */
    DialogState.prototype = {
        '_openable': function () {
            return (this.get('initialised') && this.get('closed') && !this.get('opening'));
        },
        '_closable': function () {
            return (!this.get('closing') && this.get('opened'));
        },
        '_loadable': function () {
            return (!this.get('loading') && !this.get('loaded'));
        },
        '_insertable': function () {
            return (this.get('initialised') && !this.get('inserting'));
        }
    };

    refinery.extend(DialogState.prototype, refinery.ObjectState.prototype);


    /**
     * @constructor
     * @extends {refinery.Object}
     * @param {{title: string, url: string}=} options
     * @return {refinery.admin.Dialog}
     */
    refinery.Object.create(
        /**
         * @extends {refinery.Object.prototype}
         */
        {
            name: 'Dialog',

            module: 'admin',

            options: {
                'title': '',

                /**
                 * Url which from will be loaded dialog content via xhr or iframe
                 * @type {?string}
                 */
                'url': null,
                'width': 710,
                'modal': true,
                'autoOpen': false,
                'autoResize': true
            },

            /**
             * User Interface component
             *
             * @expose
             * @type {?refinery.Object}
             */
            ui: null,

            State: DialogState,

            /**
             *
             * @expose
             *
             * @return {Object} self
             */
            close: function () {
                if (this.is('closable')) {
                    this.holder.dialog('close');
                }

                return this;
            },

            /**
             *
             * @expose
             *
             * @return {Object} self
             */
            open: function () {
                if (this.is('openable')) {
                    this.is('opening', true);
                    this.holder.dialog('open');
                }

                return this;
            },

            /**
             * Handle Insert event
             * For specific use should be implemented in subclasses
             *
             * @expose
             * @param {!jQuery} elm Element which evoke insert event
             *
             * @return {Object} self
             */
            insert: function (elm) {
                var tab = elm.closest('.ui-tabs-panel'),
                    obj, fnc;

                if (tab.length > 0) {
                    fnc = tab.attr('id').replace(/-/g, '_');
                    if (typeof this[fnc] === 'function') {
                        obj = this[fnc](elm);
                    }
                }

                if (obj) {
                    this.trigger('insert', obj);
                }

                return this;
            },

            /**
             * Bind events to dialog buttons and forms
             *
             * @expose
             * @return {undefined}
             */
            init_buttons: function () {
                var that = this,
                    holder = that.holder;

                holder.on('click', '.cancel-button, .close-button', function (e) {
                    e.preventDefault();
                    that.close();
                    return false;
                });

                holder.on('submit', 'form', function (e) {
                    var form = $(this);

                    if (!form.attr('action')) {
                        e.preventDefault();
                        e.stopPropagation();
                        that.insert(form);
                    }
                });
            },

            /**
             * Load dialog content
             *
             * @expose
             * @todo this is (still) ugly, refactor!
             *
             * @return {Object} self
             */
            load: function () {
                var that = this,
                    holder = that.holder,
                    url = that.options.url,
                    locale_input = $('#frontend_locale'),
                    params, xhr;

                if (!url) {
                    throw new Error('Url isn\'t defined. (' + that.uid + ')');
                }

                if (that.is('loadable')) {
                    that.is('loading', true);

                    params = {
                        'id': that.id,
                        'frontend_locale': locale_input.length > 0 ? locale_input.val() : 'en'
                    };

                    xhr = $.ajax(url, params);

                    xhr.fail(function () {
                        // todo xhr, status
                        holder.html($('<div/>', {
                            'class': 'flash error',
                            'html': t('refinery.admin.dialog_content_load_fail')
                        }));
                    });

                    xhr.done(function (response, status, xhr) {
                        if (status === 'success') {
                            holder.empty();
                            that.ui_holder = $('<div/>').appendTo(holder);
                            refinery.xhr.success(response, status, xhr, that.ui_holder);
                            that.ui_change();
                            that.is('loaded', true);
                        }
                    });

                    xhr.always(function () {
                        that.is('loading', false);
                        holder.removeClass('loading');
                        that.trigger('load');
                    });
                }

                return this;
            },

            ui_change: function () {
                var that = this;

                function ui_change () {
                    if (that.ui) {
                        that.ui.destroy();
                        that.ui.unsubscribe('ui:change', ui_change);
                    }

                    that.ui = refinery('admin.UserInterface', {
                        'main_content_selector': '.dialog-content-wrapper'
                    }).init(that.ui_holder);

                    that.ui.subscribe('ui:change', ui_change);
                }

                ui_change();
            },

            bind_events: function () {
                var that = this,
                    holder = that.holder;

                that.on('insert', that.close);
                that.on('open', that.load);

                holder.on('dialogopen', function () {
                    that.is({ 'opening': false, 'opened': true, 'closed': false });
                    that.trigger('open');
                });

                holder.on('dialogbeforeclose', function () {
                    // this is here because dialog can be closed via ESC or X button
                    // and in that case is not running through that.close
                    // @todo maybe purge own close - open methods
                    that.is({ 'closing': false, 'closed': true, 'opened': false });
                    that.trigger('close');
                });

                holder.on('selectableselected', '.records.ui-selectable', function (event, ui) {
                    that.insert($(ui.selected));
                });

                holder.on('click', '.pagination a', function (event) {
                    var a = $(this),
                        url = /** @type {string} */(a.attr('href'));

                    event.preventDefault();
                    event.stopPropagation();

                    $.get(url).done(
                        /**
                         * @param {json_response} response
                         * @param {string} status
                         * @param {jQuery.jqXHR} xhr
                         * @return {undefined}
                         */
                        function (response, status, xhr) {
                            holder.find('.dialog-content-wrapper')
                            .trigger('ajax:success', [response, status, xhr]);
                        }).always(function () {
                            refinery.spinner.off();
                        });
                });

                holder.on('ajax:success',
                    /**
                     *
                     * @param  {jQuery.jqXHR} xhr
                     * @param  {json_response} response
                     * @return {undefined}
                     */
                    function (xhr, response) {
                        that.upload_area(response);
                    });
            },

            /**
             * Handle uploaded resource
             *
             * @expose
             * @return {undefined}
             */
            upload_area: function () { },

            /**
             *
             * @expose
             * @return {Object} self
             */
            destroy: function () {
                if (this.ui) {
                    this.ui.destroy();
                    this.ui.unsubscribe('ui:change', this.ui_change);
                    this.ui = null;
                }

                if (this.holder && this.holder.parent().hasClass('ui-dialog')) {
                    this.holder.dialog('destroy');
                }

                return this._destroy();
            },

            /**
             * Initialization and binding
             *
             * @public
             * @expose
             *
             * @return {refinery.Object} self
             */
            init: function () {
                var holder;

                if (this.is('initialisable')) {
                    this.is('initialising', true);
                    holder = $('<div/>', {
                        'id': 'dialog-' + this.id,
                        'class': 'loading'
                    });

                    holder.dialog(this.options);
                    this.attach_holder(holder);

                    this.bind_events();
                    this.init_buttons();

                    this.is({'initialised': true, 'initialising': false});
                    this.trigger('init');
                }

                return this;
            }
        });

// Source: ~/refinery/scripts/admin/pickers/picker.js
    /**
     * @constructor
     * @extends {refinery.Object}
     * @param {Object=} options
     */
    refinery.Object.create({
        name: 'Picker',

        module: 'admin',

        /**
         * @expose
         * @type {?string}
         */
        elm_current_record_id: null,

        /**
         * @expose
         * @type {jQuery}
         */
        elm_record_holder: null,

        /**
         * @expose
         * @type {jQuery}
         */
        elm_no_picked_record: null,

        /**
         * @expose
         * @type {jQuery}
         */
        elm_remove_picked_record: null,

        /**
         * refinery admin dialog
         *
         * @expose
         *
         * @type {?refinery.Object}
         */
        dialog: null,

        /**
         * Open dialog
         *
         * @expose
         *
         * @return {Object} self
         */
        open: function () {
            this.dialog.open();
            return this;
        },

        /**
         * Close dialog
         *
         * @expose
         *
         * @return {Object} self
         */
        close: function () {
            this.dialog.close();
            return this;
        },

        /**
         * Insert record to form
         *
         * @param {{id: (string|number)}} record
         * @expose
         *
         * @return {Object} self
         */
        insert: function (record) {
            refinery.log(record);
            return this;
        },

        /**
         * Bind events
         *
         * @protected
         * @expose
         *
         * @return {undefined}
         */
        bind_events: function () {
            var that = this,
                holder = that.holder;

            that.dialog.on('insert', function (record) {
                that.insert(record);
            });

            holder.find('.current-record-link').on('click', function (e) {
                e.preventDefault();
                that.open();
            });

            holder.find('.remove-picked-record').on('click', function (e) {
                e.preventDefault();
                that.elm_current_record_id.val('');
                that.elm_record_holder.empty();
                that.elm_remove_picked_record.addClass('hide');
                that.elm_no_picked_record.removeClass('hide');
                that.trigger('remove');
            });
        },

        /**
         * Abstract method
         *
         * abstract
         * @expose
         */
        init_dialog: function () {

        },

        /**
         * Initialization and binding
         *
         * @param {!jQuery} holder
         *
         * @return {refinery.Object} self
         */
        init: function (holder) {
            if (this.is('initialisable')) {
                this.is('initialising', true);
                this.attach_holder(holder);
                this.elm_current_record_id = holder.find('.current-record-id');
                this.elm_record_holder = holder.find('.record-holder');
                this.elm_no_picked_record = holder.find('.no-picked-record-selected');
                this.elm_remove_picked_record = holder.find('.remove-picked-record');
                this.init_dialog();
                this.bind_events();
                this.is({'initialised': true, 'initialising': false});
                this.is({'initialising' : false, 'initialised': true });
                this.trigger('init');
            }

            return this;
        }
    });

// Source: ~/refinery/scripts/admin/dialogs/image_dialog.js
    /**
     * @constructor
     * @extends {refinery.admin.Dialog}
     * @param {Object=} options
     */
    refinery.Object.create({

        /**
         * test
         * @param {image_dialog_options} options
         */
        objectConstructor: function (options) {
            options.url = refinery.admin.backend_path + '/dialogs/image/' + options.image_id;

            refinery.Object.apply(this, arguments);
        },

        objectPrototype: refinery('admin.Dialog', {
            title: t('refinery.admin.image_dialog_title')
        }, true),

        name: 'ImageDialog',

        /**
         * Propagate selected image wth attributes to dialog observers
         *
         * @param {!jQuery} form
         * @return {Object} self
         */
        insert: function (form) {
            var alt = form.find('#image-alt').val(),
                id = form.find('#image-id').val(),
                size_elm = form.find('#image-size .ui-selected a'),
                size = size_elm.data('size'),
                geometry = size_elm.data('geometry'),
                sizes = form.find('#image-preview').data();

            this.trigger('insert', {
                'id': id,
                'alt': alt,
                'size': size,
                'geometry': geometry,
                'sizes': sizes
            });

            return this;
        }
    });

// Source: ~/refinery/scripts/admin/dialogs/images_dialog.js
    /**
     * @constructor
     * @extends {refinery.admin.Dialog}
     * @param {Object=} options
     */
    refinery.Object.create({

        objectPrototype: refinery('admin.Dialog', {
            title: t('refinery.admin.images_dialog_title'),
            url: refinery.admin.backend_path + '/dialogs/images'
        }, true),

        name: 'ImagesDialog',

        /**
         * Handle image linked from library
         *
         * @expose
         * @param {!jQuery} li selected row
         * @return {images_dialog_object}
         */
        existing_image_area: function (li) {
            li.removeClass('ui-selected');

            return /** @type {images_dialog_object} */(li.data('dialog'));
        },

        /**
         * Handle image linked by url
         *
         * @expose
         * @param {!jQuery} form
         * @return {undefined|images_dialog_object}
         */
        external_image_area: function (form) {
            var url_input = form.find('input[type="url"]:valid'),
                alt_input = form.find('input[type="text"]:valid'),
                url = /** @type {string} */(url_input.val()),
                alt = /** @type {string} */(alt_input.val()),
                obj;

            if (url) {
                obj = {
                    url: url,
                    alt: alt
                };

                url_input.val('');
                alt_input.val('');
            }

            return obj;
        },

        /**
         * Handle uploaded image
         *
         * @expose
         * @param {json_response} json_response
         * @return {undefined}
         */
        upload_area: function (json_response) {
            var that = this,
                image = /** @type {images_dialog_object} */(json_response.image),
                holder = that.holder;

            if (image) {
                that.trigger('insert', image);
                holder.find('li.ui-selected').removeClass('ui-selected');
                holder.find('.ui-tabs').tabs({ 'active': 0 });
            }
        }
    });

// Source: ~/refinery/scripts/admin/dialogs/pages_dialog.js
    /**
     * @constructor
     * @extends {refinery.admin.Dialog}
     * @param {Object=} options
     */
    refinery.Object.create({
        objectPrototype: refinery('admin.Dialog', {
            title: t('refinery.admin.pages_dialog_title'),
            url: refinery.admin.backend_path + '/dialogs/pages'
        }, true),

        name: 'PagesDialog',

        /**
         * Dialog email tab action processing
         *
         * @param {!jQuery} form
         * @expose
         *
         * @return {undefined|pages_dialog_object}
         */
        email_link_area: function (form) {
            var email_input = form.find('#email_address_text:valid'),
                subject_input = form.find('#email_default_subject_text'),
                body_input = form.find('#email_default_body_text'),
                recipient = /** @type {string} */(email_input.val()),
                subject = /** @type {string} */(subject_input.val()),
                body = /** @type {string} */(body_input.val()),
                modifier = '?',
                additional = '',
                result;

            if (recipient) {
                if (subject.length > 0) {
                    additional += modifier + 'subject=' + encodeURIComponent(subject);
                    modifier = '&';
                }

                if (body.length > 0) {
                    additional += modifier + 'body=' + encodeURIComponent(body);
                    modifier = '&';
                }

                result = {
                    type: 'email',
                    title: recipient,
                    url: 'mailto:' + encodeURIComponent(recipient) + additional
                };

                email_input.val('');
                subject_input.val('');
                body_input.val('');
            }

            return result;
        },

        /**
         * Dialog Url tab action processing
         *
         * @param {!jQuery} form
         * @expose
         *
         * @return {undefined|pages_dialog_object}
         */
        website_link_area: function (form) {
            var url_input = form.find('#web_address_text:valid'),
                blank_input = form.find('#web_address_target_blank'),
                url = /** @type {string} */(url_input.val()),
                blank = /** @type {boolean} */(blank_input.prop('checked')),
                result;

            if (url) {
                result = {
                    type: 'website',
                    title: url.replace(/^https?:\/\//, ''),
                    url: url,
                    blank: blank
                };

                url_input.val('http://');
                blank_input.prop('checked', false);
            }

            return result;
        },

        /**
         * Dialog Url tab action processing
         *
         * @expose
         * @param {!jQuery} li
         *
         * @return {pages_dialog_object}
         */
        pages_link_area: function (li) {
            var result = /** @type {pages_dialog_object} */(li.data('dialog'));

            result.type = 'page';
            li.removeClass('ui-selected');

            return result;
        }
    });

// Source: ~/refinery/scripts/admin/dialogs/resources_dialog.js
    /**
     * @constructor
     * @extends {refinery.admin.Dialog}
     * @param {Object=} options
     * @return {refinery.admin.ResourcesDialog}
     */
    refinery.Object.create({
        objectPrototype: refinery('admin.Dialog', {
            title: t('refinery.admin.resources_dialog_title'),
            url: refinery.admin.backend_path + '/dialogs/resources'
        }, true),

        name: 'ResourcesDialog',

        /**
         * Handle resource linked from library
         *
         * @expose
         * @param {!jQuery} li
         * @return {file_dialog_object}
         */
        existing_resource_area: function (li) {
            li.removeClass('ui-selected');

            return /** @type {file_dialog_object} */(li.data('dialog'));
        },

        /**
         * Handle uploaded file
         *
         * @param {json_response} json_response
         * @return {undefined}
         */
        upload_area: function (json_response) {
            var that = this,
                file = json_response.file,
                holder = that.holder;

            if (file) {
                that.trigger('insert', file);

                holder.find('li.ui-selected').removeClass('ui-selected');
                holder.find('.ui-tabs').tabs({ 'active': 0 });
            }
        }
    });

// Source: ~/refinery/scripts/admin/pickers/image_picker.js
    /**
     * @constructor
     * @extends {refinery.admin.Picker}
     * @param {Object=} options
     */
    refinery.Object.create({
        objectPrototype: refinery('admin.Picker', null, true),

        name: 'ImagePicker',

        /**
         * Initialize Images Dialog
         */
        init_dialog: function () {
            /**
             * refinery.admin.ImagesDialog
             */
            var dialog = refinery('admin.ImagesDialog').init();

            /**
             * Hide url tab as we can insert in picker only images from our library.
             * When it will be implemented functionality upload external image to server
             * then this can disappear
             *
             * @return {undefined}
             */
            dialog.on('load', function () {
                dialog.holder.find('a[href="#external-image-area"]').parent().hide();
            });

            this.dialog = dialog;
        },

        /**
         * Attach image to form
         *
         * @param {images_dialog_object} img
         *
         * @return {Object} self
         */
        insert: function (img) {
            this.elm_current_record_id.val(img.id);

            this.elm_record_holder.html($('<img/>', {
                'class': 'record size-medium',
                'src': img.thumbnail
            }));

            this.elm_no_picked_record.addClass('hide');
            this.elm_remove_picked_record.removeClass('hide');
            this.dialog.close();
            this.trigger('insert');

            return this;
        }
    });

// Source: ~/refinery/scripts/admin/pickers/resource_picker.js
    /**
     * @constructor
     * @extends {refinery.admin.Picker}
     * @param {Object=} options
     */
    refinery.Object.create({
        objectPrototype: refinery('admin.Picker', null, true),

        name: 'ResourcePicker',

        /**
         * Initialize Resources Dialog
         *
         */
        init_dialog: function () {
            /**
             * refinery.admin.ResourcesDialog
             */
            this.dialog = refinery('admin.ResourcesDialog').init();
        },


        /**
         * Attach resource - file to form
         *
         * @param {file_dialog_object} file
         *
         * @return {Object} self
         */
        insert: function (file) {
            var html;

            html = $('<span/>', {
                'text': file.name + ' - ' + file.size,
                'class': 'title' + ( ' ' + file.ext || '')
            });

            this.elm_current_record_id.val(file.id);

            this.elm_record_holder.html($('<a/>', {
                'src': file.url,
                'html': html,
                'class': 'record'
            }));

            this.elm_no_picked_record.addClass('hide');
            this.elm_remove_picked_record.removeClass('hide');
            this.dialog.close();
            this.trigger('insert');

            return this;
        }

    });
}(window, jQuery));