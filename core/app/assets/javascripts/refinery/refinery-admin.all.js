
(function (window, $) {

// Source: ~/refinery/scripts/admin/admin.js
/**
 * Refinery Admin namespace
 *
 * @expose
 * @type {Object}
 */
refinery.admin = {
    ui: {}
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
                        var redirected = xhr.getResponseHeader('X-XHR-Redirected-To');

                        dialog.dialog('close');
                        dialog.dialog('destroy');

                        if (redirected) {
                            Turbolinks.visit(redirected + param);
                        } else if (status === 'error') {
                            refinery.xhr.success(response, status, xhr, form, true);
                        } else {
                            Turbolinks.visit(url);
                        }

                    }
                });
            };

            buttons[t('refinery.admin.form_unsaved_continue')] = function () {
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

        init_inputs: function () {
            var that = this,
                form = that.holder,
                submit_btn = form.find('.form-actions .submit-button'),
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
        },

        fly_form_actions: function (left_buttons, holder, $window) {
            var
                window_position = $window.scrollTop() + $window.height(),
                form_actions_pos = holder.position().top;

            if (window_position < form_actions_pos) {
                left_buttons.addClass('fly');
            } else {
                left_buttons.removeClass('fly');
            }
        },

        init_fly_form_actions: function () {
            var that = this,
                $window = $(window),
                holder = that.holder.find('.form-actions'),
                left_buttons = that.holder.find('.form-actions-left'),
                scroll_handler = function () {
                    that.fly_form_actions(left_buttons, holder, $window);
                };

            if (that.holder.find('textarea').length > 0 &&
                holder.length > 0 && left_buttons.length > 0) {

                that.fly_form_actions(left_buttons, holder, $window);
                $window.on('scroll', scroll_handler);
                that.on('destroy', function () {
                    $window.unbind('scroll', scroll_handler);
                });
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
         * @type {string}
         */
        fade_elements_selector: '#menu, #add-page-part, #delete-page-part, ' +
                                '.locale-picker, .field:not(:has(#page-tabs)), ' +
                                '#page-part-editors, #more-options-field, .form-actions',

        /**
         * Delete page part
         *
         * @param {string} delete_url
         *
         * @return {undefined}
         */
        delete_part: function (delete_url) {
            var that = this,
                holder = that.holder,
                tab_id = holder.tabs('option', 'active'),
                part_title = that.page_parts.find('.ui-state-active a').text(),
                input_page_parts_attributes_id = $('#page_parts_attributes_' + tab_id + '_id');

            if (confirm(t('refinery.admin.form_page_parts_remove', { 'title': part_title }))) {
                holder.find('.ui-tabs-nav li:eq(' + tab_id + ')').remove();
                holder.find('.ui-tabs-panel:eq(' + tab_id + ')').remove();
                holder.find('.ui-tabs-nav li a').each(function (i) {
                    holder.find($(this).attr('href') + ' .part-position').val(i);
                });
                holder.tabs('refresh');

                if (input_page_parts_attributes_id.length > 0) {
                    $.ajax({
                        url: delete_url + '/' + input_page_parts_attributes_id.val(),
                        type: 'DELETE',
                        dataType: 'JSON',
                        success: function () {
                            input_page_parts_attributes_id.remove();
                            that.trigger('part:delete');
                        }
                    });
                }
            }
        },

        /**
         * Add part
         *
         * @param {string} add_url
         * @param {jQuery} input_title
         *
         * @return {undefined}
         */
        add_part: function (add_url, input_title) {
            var that = this,
                part_title = $.trim(/** @type {string} */(input_title.val())),
                page_part_editors = $('#page-part-editors'),
                part_index = that.holder.find('.ui-tabs-nav li').length,
                tab_title = '#page_part_' + part_title.toLowerCase().replace(/\s/g, '_'),
                tab_tpl,
                process_response;

            process_response = function (response) {
                if (response.html) {
                    tab_tpl = '<li><a href="' + tab_title + '">' + part_title + '</a></li>';

                    page_part_editors.append(response.html);
                    that.page_parts.append(tab_tpl);
                    that.holder.tabs('refresh');
                    that.holder.tabs('option', 'active', part_index);
                    that.dialog_holder.dialog('close');
                    input_title.val('');
                    that.trigger('part:add');
                } else {
                    refinery.flash('error', t('refinery.xhr_error'));
                }
            };

            if (part_title.length > 0) {
                if ($(tab_title).length === 0) {
                    $.getJSON(add_url, { 'title': part_title, 'part_index': part_index })
                        .fail(function () {
                            refinery.flash('error', t('refinery.xhr_error'));
                        })
                        .done(function (response) {
                            process_response(response);
                        });
                } else {
                    alert(t('refinery.admin.form_page_parts_part_exist'));
                }
            } else {
                alert(t('refinery.admin.form_page_parts_title_missing'));
            }
        },

        /**
         * Bind add, delete events to buttons
         *
         * @param {jQuery} add_page_part_btn
         * @param {jQuery} delete_page_part_btn
         *
         * @return {undefined}
         */
        bind_add_delete_part_events_to_buttons: function (add_page_part_btn, delete_page_part_btn) {
            var that = this,
                dialog_holder = that.dialog_holder,
                input_title = dialog_holder.find('#new-page-part-title');

            add_page_part_btn.on('click', function (e) {
                e.preventDefault();

                dialog_holder.dialog({
                    title: t('refinery.admin.form_page_parts_add_part_dialog_title'),
                    modal: true,
                    resizable: false,
                    autoOpen: true,
                    width: 400,
                    height: 240
                });

                dialog_holder.removeClass('hide');
            });

            delete_page_part_btn.on('click', function (e) {
                e.preventDefault();
                that.delete_part(delete_page_part_btn.attr('href'));
            });

            dialog_holder.on('click', '.cancel-button', function (e) {
                e.preventDefault();
                dialog_holder.dialog('close');
                input_title.val('');
            });

            dialog_holder.on('click', '.submit-button', function (e) {
                e.preventDefault();
                that.add_part(add_page_part_btn.attr('href'), input_title);

            });

            input_title.keypress(function (e) {
                if (e.which === 13) {
                    e.preventDefault();
                    that.add_part(add_page_part_btn.attr('href'), input_title);
                }
            });
        },

        /**
         * Initialize page part dialog and bind events
         *
         * @return {undefined}
         */
        init_add_remove_part: function () {
            var that = this,
                add_page_part_btn = $('#add-page-part'),
                delete_page_part_btn = $('#delete-page-part');

            if (add_page_part_btn.length > 0 && delete_page_part_btn.length > 0) {
                that.dialog_holder = $('<div/>', {
                    html: '<div class="field">' +
                          '  <input class="larger widest" placeholder="' +
                            t('refinery.admin.label_title') +
                          '" id="new-page-part-title">' +
                          '  <input type="hidden" id="new-page-part-index">' +
                          '</div>' +
                          '<div class="form-actions clearfix">' +
                          '  <div class="form-actions-left">' +
                          '    <input type="submit" value="' +
                            t('refinery.admin.button_create') +
                          '" class="button submit-button">' +
                          '  </div>' +
                          '</div>'
                });

                that.bind_add_delete_part_events_to_buttons(add_page_part_btn,
                    delete_page_part_btn);
            }
        },

        /**
         * Handle reordering
         *
         * @return {undefined}
         */
        start_reordering_page_parts: function () {
            this.holder.tabs('disable');
            this.page_parts.addClass('reordering');
            this.reorder_page_part_btn.addClass('hide');
            this.reorder_page_part_done_btn.removeClass('hide');
            this.page_parts.sortable('enable');
            this.fade_elements.fadeTo(500, 0.3);
        },

        /**
         * Handle stoping reordering
         *
         * @return {undefined}
         */
        stop_reordering_page_parts: function () {
            this.page_parts.removeClass('reordering');
            this.reorder_page_part_done_btn.addClass('hide');
            this.reorder_page_part_btn.removeClass('hide');
            this.page_parts.sortable('disable');
            this.fade_elements.fadeTo(500, 1);
            this.holder.tabs('enable');
        },

        /**
         * Initialize parts reordering
         *
         * @return {undefined}
         */
        init_reorder_parts: function () {
            var that = this;

            that.page_parts.sortable({
                items: 'li',
                enabled: false,
                stop: function () {
                    that.holder.find('.ui-tabs-nav li a').each(function (i) {
                        that.holder.find($(this).attr('href') + ' .part-position').val(i);
                    });
                }
            }).sortable('disable');

            that.reorder_page_part_btn = $('#reorder-page-part');
            that.reorder_page_part_done_btn = $('#reorder-page-part-done');
            that.reorder_page_part_btn.on('click', function (e) {
                e.preventDefault();
                that.start_reordering_page_parts();
            });

            that.reorder_page_part_done_btn.on('click', function (e) {
                e.preventDefault();
                that.stop_reordering_page_parts();
            });

            that.fade_elements = $(that.fade_elements_selector);
        },

        /**
         *
         * @param {boolean=} removeGlobalReference if is true instance will be removed
         *                   from refinery.Object.instances
         *
         * @return {Object} self
         */
        destroy: function (removeGlobalReference) {
            if (this.is('initialised')) {
                this.page_parts = null;
                this.holder.parent()
                    .find('#reorder-page-part, #reorder-page-part-done, #add-page-part, #delete-page-part')
                    .off();
                this.reorder_page_part_done_btn = null;
                this.reorder_page_part_btn = null;

                if (this.dialog_holder) {
                    if (this.dialog_holder.hasClass('ui-dialog')) {
                        this.dialog_holder.dialog('destroy');
                    }

                    this.dialog_holder.off();
                    this.dialog_holder.remove();
                    this.dialog_holder = null;
                }

                this.fade_elements = null;
            }
            refinery.Object.prototype.destroy.apply(this, [removeGlobalReference]);

            return this;
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
                this.page_parts = holder.find('#page-parts');
                this.init_add_remove_part();
                this.init_reorder_parts();
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
     * @param  {Object} ui
     * @return {undefined}
     */
    refinery.admin.ui.formPageParts = function (holder, ui) {
        holder.find('#page-tabs').each(function () {
            var page_parts = refinery('admin.FormPageParts').init($(this));

            page_parts.on('part:add', function () {
                ui.reload(holder);
            });
            page_parts.on('part:delete', function () {
                ui.reload(holder);
            });
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

        /**
         *
         * @expose
         * @param {boolean=} removeGlobalReference if is true instance will be removed
         *                   from refinery.Object.instances
         *
         * @return {Object} self
         */
        destroy: function (removeGlobalReference) {
            this.holder.nestedSortable('destroy');
            this.set = null;

            this._destroy(removeGlobalReference);

            return this;
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
     */
    refinery.Object.create({

        name: 'UserInterface',

        module: 'admin',

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
        },

        init_collapsible_lists: function () {
            this.holder.find('.collapsible-list').accordion({
                collapsible: true,
                heightStyle: 'content'
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

        init_deletable_records: function () {
            var holder = this.holder;

            function hideRecord (elm) {
                var record = elm.closest('.record');
                record = record.length > 0 ? record : holder.find('.record');
                record = record.length > 0 ? record : elm.closest('li');

                if (record.length > 0) {
                    record.fadeOut('normal', function () {
                        record.remove();
                    });
                }
            }

            holder.on('confirm:complete', '.records .delete', function (event, answer) {
                if (answer) {
                    hideRecord($(this));
                }
            });

            holder.on('click', 'a.delete', function () {
                if (!this.hasAttribute('data-confirm')) {
                    hideRecord($(this));
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
                        ui.newPanel.find('input.text, textarea').focus();
                    }
                });
            });
        },

        bind_events: function () {
            var that = this,
                holder = that.holder;

            holder.on('click', '.flash-close', function (e) {
                e.preventDefault();
                $(this).parent().fadeOut();
                return false;
            });

            holder.on('click', '.tree .toggle', function (e) {
                e.preventDefault();
                that.toggle_tree_branch($(this).parents('li:first'));
            });

            holder.on('ajax:success', function (event, response, status, xhr) {
                if (response && typeof response === 'object') {
                    event.preventDefault();
                    refinery.xhr.success(response, status, xhr, $(event.target), true);
                    that.reload(holder);
                }
            });

            holder.on('ajax:error', function (event, xhr, status) {
                refinery.xhr.error(xhr, status);
            });

            holder.on('click', '.checkboxes-cmd', function (e) {
                e.preventDefault();
                var a = $(this),
                    parent = a.parent(),
                    checkboxes = parent.find('input:checkbox'),
                    checked = a.hasClass('all');

                checkboxes.prop('checked', checked);
                parent.find('.checkboxes-cmd').toggleClass('hide');
            });

            holder.on('click', '.ui-selectable li', function (e) {
                var elm = $(this);

                e.preventDefault();
                if (!elm.parent().hasClass('ui-selectable-multiple')) {
                    elm.siblings().removeClass('ui-selected');
                }

                elm.toggleClass('ui-selected');

                return false;
            });
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

            that.init_deletable_records();

            for (fnc in ui) {
                if (ui.hasOwnProperty(fnc) && typeof ui[fnc] === 'function') {
                    ui[fnc](holder, that);
                }
            }
        },

        /**
         * Removing all refinery instances under holder, and reloading self.
         * This is important when ajax replace current content of holder so, some objects
         * may not longer exist and we need remove all references to them.
         *
         * @param {!jQuery} holder
         *
         * @return {Object} self
         */
        reload: function (holder) {
            var holders = this.holder.find('.refinery-instance');

            try {
                holders.each(function () {
                    var instances = $(this).data('refinery-instances'),
                        instance;

                    for (var i = instances.length - 1; i >= 0; i--) {
                        instance = refinery.Object.instances.get(instances[i]);
                        instance.destroy(true);
                    }
                });
            } catch (e) {
                console.log(e);
            }

            this.holder.off();
            this.state = new this.State();
            return this.init(holder);
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

            State: /** @type {Object} */(function () {
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
                    '_submittable': function () {
                        return (this.get('initialised') && !this.get('submitting'));
                    },
                    /** @expose */
                    '_insertable': function () {
                        return (this.get('initialised') && !this.get('inserting'));
                    }
                };

                refinery.extend(DialogState.prototype, refinery.ObjectState.prototype);

                return DialogState;
            }()),

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
             *
             * @expose
             *
             * @return {Object} self
             */
            submit: function () {
                var form = this.holder.find('form');

                if (form.length > 0) {
                    this.submit_form(form);
                }

                return this;
            },


            /**
             * Handle .submit-button click
             * which doesn't have form
             * Should be implemented by subclasses
             *
             * @expose
             *
             * @todo  write
             * @return {undefined}
             */
            submit_button: function () { },

            /**
             * Submit form
             * -- just dirty implementation
             * Implement for specific cases in subclasses
             *
             *
             * @expose
             * @param {jQuery} form
             *
             * @return {undefined}
             */
            submit_form: function (form) {
                var that = this;

                if (that.is('submittable')) {
                    that.is('submitting', true);

                    $.ajax({
                        url: form.attr('action'),
                        type: form.attr('method'),
                        data: form.serialize(),
                        dataType: 'JSON'
                    }).done(function (response, status, xhr) {
                        that.xhr_done(response, status, xhr);

                        that.trigger('submit');
                    }).always(function () {
                        that.is({'submitted': true, 'submitting': false});
                    });
                }
            },

            /**
             * Handle Insert event
             * For specific use should be implemented in subclasses
             *
             * @expose
             *
             * @return {Object} self
             */
            insert: function () {
                var li = this.holder.find('.ui-selected');
                if (li.length > 0) {
                    this.trigger('insert', li.data());
                }

                return this;
            },

            /**
             * Bind events to dialog buttons and forms
             *
             * @return {undefined}
             */
            init_buttons: function () {
                var that = this;

                that.holder.on('click', '.cancel-button, .close-button', function (e) {
                    e.preventDefault();
                    that.close();
                    return false;
                });

                that.holder.on('click', '.submit-button', function (e) {
                    if ($(this).closest('form').length === 0) {
                        e.preventDefault();
                        that.submit_button();
                        return false;
                    }
                });

                that.holder.on('submit', 'form', function (e) {
                    e.preventDefault();
                    that.submit_form($(this));
                    return false;
                });

                that.holder.on('click', '.insert-button', function (e) {
                    e.preventDefault();
                    that.insert();
                    return false;
                });
            },

            /**
             * Process xhr response and reloading ui interface
             *
             * @expose
             *
             * @param  {Object} response
             * @param  {string} status
             * @param  {Object} xhr
             *
             * @return {undefined}
             */
            xhr_done: function (response, status, xhr) {
                var that = this,
                    ui = that.ui,
                    holder = ui.holder;

                refinery.xhr.success(response, status, xhr, holder);
                ui.reload(holder);
            },

            /**
             * Xhr fail processing
             *
             * @expose
             *
             * @param  {Object} xhr
             * @param  {string} status
             *
             * @return {undefined}
             */
            xhr_fail: function (xhr, status) {
                refinery.xhr.error(xhr, status);
            },

            init_paginate: function () {
                var that = this,
                    holder = that.holder;

                holder.on('click', '.pagination > a', function (e) {
                    e.preventDefault();
                    $.ajax({
                        url: this.getAttribute('href'),
                        dataType: 'JSON'
                    })
                    .fail(refinery.xhr.error)
                    .done(function (response, status, xhr) {
                        that.xhr_done(response, status, xhr);
                    });
                });
            },

            /** @expose */
            after_load: function () {
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
                    params, tmp, xhr;

                if (that.is('loadable')) {
                    that.is('loading', true);

                    if (url[0] === '#') {
                        $(function () {
                            holder.html($(url).html());
                            that.is({'loaded': true, 'loading': false});
                            that.after_load();
                            that.trigger('load');
                        });
                    } else {
                        params = {
                            'id': that.id,
                            'frontend_locale': locale_input.length > 0 ? locale_input.val() : 'en'
                        };

                        xhr = $.ajax(url, params);

                        xhr.fail(function (xhr, status) {
                            // todo xhr, status
                            holder.html($('<div/>', {
                                'class': 'flash error',
                                'html': t('refinery.admin.dialog_content_load_fail')
                            }));
                        });

                        xhr.always(function () {
                            that.is('loading', false);
                            holder.removeClass('loading');
                        });

                        xhr.done(function (response, status, xhr) {
                            var ui_holder;

                            if (status === 'success') {
                                holder.empty();
                                ui_holder = $('<div/>').appendTo(holder);
                                refinery.xhr.success(response, status, xhr, ui_holder);
                                that.ui.init(ui_holder);
                                that.is('loaded', true);
                                that.after_load();
                                that.trigger('load');
                            }
                        });

                    }
                }

                return this;
            },

            bind_events: function () {
                var that = this;
                //that.on('submit', that.close);
                that.on('insert', that.close);
                that.on('open', that.load);

                that.holder.on('dialogopen', function () {
                    that.state.toggle('opening', 'opened', 'closed');
                    that.trigger('open');
                });

                that.holder.on('dialogbeforeclose', function () {
                    // this is here because dialog can be closed via ESC or X button
                    // and in that case is not running through that.close
                    // @todo maybe purge own close, open methods
                    that.is('closing', true);
                    that.state.toggle('closing', 'closed', 'opened');
                    that.trigger('close');
                });
            },

            /**
             *
             * @expose
             * @param {boolean=} removeGlobalReference if is true instance will be removed
             *                   from refinery.Object.instances
             *
             * @return {Object} self
             */
            destroy: function (removeGlobalReference) {
                if (this.ui) {
                    this.ui.destroy(true);
                    this.ui = null;
                }

                this._destroy(removeGlobalReference);;

                return this;
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
                if (this.is('initialisable')) {
                    this.is('initialising', true);
                    this.holder = $('<div/>', {
                        'id': 'dialog-' + this.id,
                        'class': 'loading'
                    });

                    this.attach_holder(this.holder);

                    this.ui = refinery('admin.UserInterface');
                    this.holder.dialog(this.options);

                    this.bind_events();
                    this.init_buttons();
                    this.init_paginate();
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
         *
         * @type {?string}
         */
        elm_current_record_id: null,

        /**
         *
         * @type {?(jQuerySelector|jQuery)}
         */
        elm_record_holder: null,

        /**
         *
         * @type {?(jQuerySelector|jQuery)}
         */
        elm_no_picked_record: null,

        /**
         *
         * @type {?(jQuerySelector|jQuery)}
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
            console.log(record);
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
         * Initialization and binding
         *
         * @param {!jQuery} holder
         * @param {!refinery.Object} dialog
         *
         * @return {refinery.Object} self
         */
        init: function (holder, dialog) {
            if (this.is('initialisable')) {
                this.is('initialising', true);
                this.attach_holder(holder);
                this.elm_current_record_id = holder.find('.current-record-id');
                this.elm_record_holder = holder.find('.record-holder');
                this.elm_no_picked_record = holder.find('.no-picked-record-selected');
                this.elm_remove_picked_record = holder.find('.remove-picked-record');
                this.dialog = dialog.init(holder);
                this.bind_events();
                this.is({'initialised': true, 'initialising': false});
                this.is({'initialising' : false, 'initialised': true });
                this.trigger('init');
            }

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
                url: '/refinery/dialogs/images'
            }, true),

            name: 'ImagesDialog',

            /**
             * Select first image in library
             * Put focus to first text input element
             *
             * @return {undefined}
             */
            after_load: function () {
                this.holder.find('.records li').first().addClass('ui-selected');
                this.holder.find('input.text:visible').focus();
            },

            /**
             * Handle image linked from library
             *
             * @return {?images_dialog_object}
             */
            library_tab: function (tab) {
                var img = tab.find('.ui-selected .image img'),
                    size_elm = tab.find('.image-dialog-size.ui-selected a'),
                    resize = tab.find('input:checkbox').is(':checked'),
                    /** @type {?images_dialog_object} */
                    obj = null;

                if (img.length > 0) {
                    obj = img.data();
                    obj.type = 'library';
                    obj.size = 'original';

                    if (size_elm.length > 0 && resize) {
                        obj.size = size_elm.data('size');
                        obj.geometry = size_elm.data('geometry');
                    }
                }

                return obj;
            },

            /**
             * Handle image linked by url
             *
             * @return {?images_dialog_object}
             */
            url_tab: function (tab) {
                var url_input = tab.find('input.text:valid'),
                    url = url_input.val(),
                    /** @type {?images_dialog_object} */
                    obj = null;

                if (url) {
                    obj = {
                        'size': 'original',
                        'original': url,
                        'type': 'external'
                    };
                }

                return obj;
            },

            /**
             * Handle upload
             *
             * @return {undefined}
             */
            upload_tab: function () {

            },

            /**
             * Propagate selected image wth attributes to dialog observers
             *
             * @return {Object} self
             */
            insert: function () {
                var tab = this.holder.find('div[aria-expanded="true"]'),
                    obj = null;

                switch (tab.attr('id')) {
                case 'existing-image-area':
                    obj = this.library_tab(tab);

                    break;
                case 'external-image-area':
                    obj = this.url_tab(tab);

                    break;
                default:
                    break;
                }

                if (obj) {
                    this.trigger('insert', obj);
                }

                return this;
            }
        });

// Source: ~/refinery/scripts/admin/dialogs/links_dialog.js
    /**
     * @constructor
     * @extends {refinery.admin.Dialog}
     * @param {Object=} options
     */
    refinery.Object.create({
            objectPrototype: refinery('admin.Dialog', {
                title: t('refinery.admin.links_dialog_title'),
                url: '/refinery/dialogs/links'
            }, true),

            name: 'LinksDialog',

            after_load: function () {
                this.holder.find('.records li').first().addClass('ui-selected');
            },

            /**
             * Dialog email tab action processing
             *
             * @param {!jQuery} tab
             *
             * @return {?link_dialog_object}
             */
            email_tab: function (tab) {
                var email_input = tab.find('#email_address_text:valid'),
                    subject_input = tab.find('#email_default_subject_text'),
                    body_input = tab.find('#email_default_body_text'),
                    recipient = /** @type {string} */(email_input.val()),
                    subject = /** @type {string} */(subject_input.val()),
                    body = /** @type {string} */(body_input.val()),
                    modifier = '?',
                    additional = '',
                    /** @type {?link_dialog_object} */
                    result = null,
                    i;

                subject = encodeURIComponent(subject);
                body = encodeURIComponent(body);

                if (recipient) {
                    if (subject.length > 0) {
                        additional += modifier + 'subject=' + subject;
                        modifier = '&';
                    }

                    if (body.length > 0) {
                        additional += modifier + 'body=' + body;
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
             * @param {!jQuery} tab
             *
             * @return {?link_dialog_object}
             */
            website_tab: function (tab) {
                var url_input = tab.find('#web_address_text:valid'),
                    blank_input = tab.find('#web_address_target_blank'),
                    url = /** @type {string} */(url_input.val()),
                    blank = /** @type {boolean} */(blank_input.prop('checked')),
                    /** @type {?link_dialog_object} */
                    result = null;

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
             * Process insert action by tab type
             *
             * @return {Object} self
             */
            insert: function () {
                var holder = this.holder,
                    tab = holder.find('div[aria-expanded="true"]'),
                    /** @type {?link_dialog_object} */
                    obj = null;

                switch (tab.attr('id')) {
                case 'links-dialog-pages':
                    obj = tab.find('.ui-selected').data('link');
                    obj.type = 'page';

                    break;
                case 'links-dialog-website':
                    obj = this.website_tab(tab);

                    break;
                case 'links-dialog-email':
                    obj = this.email_tab(tab);

                    break;
                default:
                    break;
                }

                if (obj) {
                    this.trigger('insert', obj);
                }

                return this;
            }

        });

// Source: ~/refinery/scripts/admin/dialogs/resources_dialog.js
    /**
     * @constructor
     * @extends {refinery.admin.Dialog}
     * @param {Object=} options
     */
    refinery.Object.create({
        objectPrototype: refinery('admin.Dialog', {
            title: t('refinery.admin.resources_dialog_title'),
            url: '/refinery/dialogs/resources'
        }, true),

        name: 'ResourcesDialog',

        after_load: function () {
            this.holder.find('.records li').first().addClass('ui-selected');
        },

        /**
         * Propagate selected file wth attributes to dialog observers
         *
         * @return {Object} self
         */
        insert: function () {
            var li = this.holder.find('.ui-selected'),
                /** @type {?file_dialog_object} */
                obj = null;

            if (li.length > 0) {
                obj = {
                    id: li.attr('id').replace('dialog-resource-', ''),
                    url: li.data('url'),
                    html: li.html(),
                    type: 'library'
                };

                this.trigger('insert', obj);
            }

            return this;
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
         * Attach image to form
         *
         * @param {{id: string, size: string, medium: string}} img
         *
         * @return {Object} self
         */
        insert: function (img) {
            if (img) {
                this.elm_current_record_id.val(img.id);
                this.holder.find('.current-image-size').val(img.size);

                this.elm_record_holder.html($('<img/>', {
                    'class': 'size-medium',
                    'src': img.medium
                }));

                this.elm_no_picked_record.addClass('hide');
                this.elm_remove_picked_record.removeClass('hide');
                this.dialog.close();
                this.trigger('insert');
            }

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
         * Attach resource to form
         *
         * @param {{id: string, url: string, html: string}} resource
         *
         * @return {Object} self
         */
        insert: function (resource) {
            if (resource) {
                this.elm_current_record_id.val(resource.id);

                this.elm_record_holder.html($('<a/>', {
                    src: resource.url,
                    html: resource.html
                }));

                this.elm_no_picked_record.addClass('hide');
                this.elm_remove_picked_record.removeClass('hide');
                this.dialog.close();
                this.trigger('insert');
            }

            return this;
        }

    });
}(window, jQuery));