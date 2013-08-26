
(function (window, $) {

// Source: ~/refinery/scripts/refinery.js
    /**
     * @return {Object}
     */
    function refinery () {
        return refinery.newInstance.apply(refinery, arguments);
    }

    /**
     * Return instance of object defined by path (namespace)
     *
     * @param {string} path
     * @param {*=} options
     * @param {boolean=} is_prototype
     *
     * @return {Object}
     */
    refinery.newInstance = function (path, options, is_prototype) {
        var parents = path.split('.'),
            Parent = this;

        while (parents.length) {
            Parent = Parent[parents.shift()];
        }

        return new Parent(options, is_prototype);
    };

    /**
     * Extend Child Object with Parent properties
     *
     * @param {Object} Child
     * @param {Object} Parent
     *
     * @return {Object} Child
     */
    refinery.extend = function (Child, Parent) {
        var key;
        for (key in Parent) {
            if (Parent.hasOwnProperty(key) && !Child.hasOwnProperty(key)) {
                Child[key] = Parent[key];
            }
        }

        return Child;
    };

    /**
     * Include html flash message into flash container
     *
     * @expose
     *
     * @param {string} type
     * @param {string} message
     */
    refinery.flash = function (type, message) {
        var holder = $('#flash-wrapper').empty(),
            div = $('<div/>', {
                'class': 'flash flash-' + type,
                'html': message
            }).appendTo(holder);

        if (div.find('.flash-close').length === 0) {
            $('<a/>', {
                'class': 'flash-close',
                'text': 'close',
                'href': '#'
            }).appendTo(div);
        }
    };

    /**
     * Validator
     *
     * @expose
     * @type {Object}
     */
    refinery.validator = {

        /**
         * Email RegExp
         *
         * @expose
         *
         * @type {RegExp}
         */
        email: new RegExp(/^([a-z0-9_\.\-]+)@([\da-z\.\-]+)\.([a-z\.]{2,6})$/i),

        /**
         * Url RegExp
         *
         * @expose
         *
         * @type {RegExp}
         */
        url: new RegExp(/^(https?|ftp):\/\/([\da-z\.\-]+)\.([a-z\.]{2,6})([\/\w \.\-]*)*\/?$/i),

        /**
         * Page RegExp
         *
         * @expose
         *
         * @type {RegExp}
         */
        page: new RegExp('^(https?:\/\/' + document.location.host + '|\/[a-z0-9]+)')
    };

    /**
     * Builds an object structure for the provided namespace path,
     * ensuring that names that already exist are not overwritten. For
     * example:
     * "a.b.c" -> a = {};a.b={};a.b.c={};
     *
     * @see goog.provide and goog.provideSymbol.
     * @expose
     * @param {string} path to the object that opt_object defines.
     * @param {*=} opt_object the object to expose at the end of the path.
     * @param {Object=} opt_objectToprovideTo The object to add the path to; default
     *     is |window|.
     */
    refinery.provide = function (path, opt_object, opt_objectToprovideTo) {
        var parts = path.split('.'), part = parts.shift(),
            cur = opt_objectToprovideTo || window;

        while (part) {
            if (!parts.length && opt_object !== 'undefined') {
                cur[part] = opt_object;
            } else if (cur[part]) {
                cur = cur[part];
            } else {
                cur = cur[part] = {};
            }
            part = parts.shift();
        }
    };

    /**
     * see  https://github.com/cowboy/jquery-tiny-pubsub
     *
     * @type {Object}
     * @expose
     */
    refinery.pubsub = (function () {

        /**
         * @private
         * @type {jQuery}
         */
        var o = $({});

        return {

            /**
             * Remove ALL subscribers/callbacks
             *
             * @expose
             * @return {undefined}
             */
            unbind: function () {
                o.unbind();
            },

            /**
             * Subscribe callback on Object event
             *
             * @expose
             * @param {string} eventName
             * @param {Function} callback
             *
             * @return {undefined}
             */
            subscribe: function (eventName, callback) {
                o.on(eventName, callback);
            },


            /**
             * Unsubscribe callback on Object event
             *
             * @expose
             * @param {string} eventName
             * @param {(function (jQuery.event=): ?|string|undefined)} callback
             *
             * @return {undefined}
             */
            unsubscribe: function (eventName, callback) {
                o.off(eventName, callback);
            },

            /**
             * Broadcast Object event to their observers with event datas
             *
             * @expose
             * @param {string} eventName
             * @param {*=} data
             *
             * @return {undefined}
             */
            publish: function (eventName, data) {
                o.trigger(eventName, data);
            }
        };
    }());

    /**
     * Wrapper around xhr calls with some basic response processing
     *
     * @expose
     * @type {Object}
     */
    refinery.xhr = {

        /**
         * Create and return jquery ajax object (promise) with default refinery
         * processing of request fail or success
         *
         * @expose
         * @param {string}   url
         * @param {(Object.<string,*>|function (string,string,jQuery.jqXHR))=} data
         * @param {jQuery=} holder
         *
         * @return {jQuery.jqXHR}
         */
        make: function (url, data, holder) {
            return $.ajax({
                url: url,
                data: data,
                dataType: 'JSON'
            })
            .fail(function (xhr, status) {
                refinery.xhr.error(xhr, status);
            })
            .done(function (response, status, xhr) {
                refinery.xhr.success(response, status, xhr, holder);
            });
        },

        /**
         * todo
         *
         * @expose
         * @param {Object|string} html
         * @param {jQuery=} holder
         * @param {boolean=} replaceHolder
         *
         * @return {undefined}
         */
        processHtml: function (html, holder, replaceHolder) {
            for (var i = html.length - 1; i >= 0; i--) {
                if (typeof html[i] === 'string' && holder.length > 0) {
                    if (replaceHolder) {
                        holder.replaceWith(html[i]);
                    } else {
                        holder.html(html[i]);
                    }
                } else {
                    for (var partial_id in html[i]) {
                        if (html[i].hasOwnProperty(partial_id)) {
                            refinery.updatePartial(partial_id, html[i][partial_id]);
                        }
                    }
                }
            }
        },

        /**
         * todo
         *
         * @expose
         * @param {Object|string} message
         *
         * @return {undefined}
         */
        processMessage: function (message) {
            var holder = $('#flash-wrapper').empty(),
                i;

            if (typeof message === 'object') {
                for (i in message) {
                    if (message.hasOwnProperty(i)) {
                        holder.append(message[i]);
                    }
                }
            } else {
                holder.append(message);
            }
        },

        /**
         * Process HTTP Errors on calls
         *
         * @expose
         * @param {jQuery.jqXHR} xhr
         * @param {string=} status
         *
         * @return {undefined}
         */
        error: function (xhr, status) {
            var flash = '<b class="' + status + '">' + xhr.statusText + '</b>',
                data;

            try {
                if (xhr.responseJSON) {
                    data = xhr.responseJSON;
                } else {
                    data = JSON.parse(xhr.responseText);
                }

                if (typeof data['error'] === 'string') {
                    flash += '! ' + data['error'];
                }
            } catch (e) { }

            refinery.flash('error', flash);
        },

        /**
         *
         * @param {json_response} response
         * @param {string} status
         * @param {jQuery.jqXHR} xhr
         * @param {jQuery=} holder
         * @param {boolean=} replaceHolder
         *
         * @return {undefined}
         */
        success: function (response, status, xhr, holder, replaceHolder) {
            var redirected_to = xhr.getResponseHeader('X-XHR-Redirected-To');

            if (response.html) {
                refinery.xhr.processHtml(response.html, holder, replaceHolder);
            }

            if (response.message) {
                refinery.xhr.processMessage(response.message);
            }

            if (redirected_to) {
                window.history.pushState({
                    'refinery': true,
                    'url': redirected_to,
                    'prev_url': document.location.href
                }, '', redirected_to);
            }
        }
    };

    /**
     * Find partial, clean mess and update his content
     *
     * @param {string} id
     * @param {string} html
     *
     * @return {undefined}
     */
    refinery.updatePartial = function (id, html) {
        var partial = $('#' + id);

        partial.html(html);
    };

    /**
     * Indicate running action
     *
     * @expose
     * @type {Object}
     */
    refinery.spinner = {

        /**
         * Show spinner
         *
         * @expose
         * @return {undefined}
         */
        on: function () {
            $('body')
            .addClass('loading')
            .prop('aria-busy', true);
        },

        /**
         * Turn off spinner
         *
         * @expose
         * @return {undefined}
         */
        off: function () {
            $('body')
            .removeClass('loading')
            .prop('aria-busy', false);
        }
    };

    refinery.provide('refinery', refinery);

// Source: ~/refinery/scripts/object_state.js
    /**
     * refinery Object State
     *
     * @constructor
     * @expose
     * @param {Object=} default_states
     *    Usage:
     *        new refinery.ObjectState();
     *
     * @todo measure perf and if needed refactor, use bit masks, fsm or something else.
     *               Invent better solution because inheritance and modifications looks for me ugly ;/
     *               On other side "if(this.is('closable')).." is
     *               better than: "if (this.opened && !this.closing..) ..".
     */
    refinery.ObjectState = function (default_states) {
        default_states = default_states || {};
        this.states = $.extend(default_states, this.states);
    };

    /**
     * @typedef {refinery.ObjectState}
     */
    refinery.ObjectState.prototype = {
        /**
         * States holder
         *
         * @private
         * @type {?Object}
         */
        states: {},

        '_initialisable' : function () {
            return !(this.get('initialising') || this.get('initialised'));
        },

        /**
         * set state
         *
         * @param {string|Object} state
         * @param {boolean=} value
         *
         * @return {undefined}
         */
        set: function (state, value) {
            var key;
            if (typeof state === 'object') {
                for (key in state) {
                    if (state.hasOwnProperty(key)) {
                        this.states[key] = !!state[key];
                    }
                }
            } else {
                this.states[state] = (typeof value === 'undefined') ? true : !!value;
            }
        },

        /**
         * get state
         *
         * @expose
         * @param {string} state
         *
         * @return {boolean}
         */
        get: function (state) {
            return !!this.states[state];
        },

        /**
         * Work with object states
         *
         * @expose
         * @param {string} action
         *
         * @return {boolean}
         */
        is: function (action) {
            return !!(this.states[action] || (this['_' + action] && this['_' + action]()));
        }
    };

// Source: ~/refinery/scripts/object.js
    /**
     * Refinery Object
     *
     * @constructor
     * @expose
     *
     * @param {Object=} options
     * @param {boolean=} is_prototype
     */
    refinery.Object = function (options, is_prototype) {
        this.id = refinery.Object.guid++;
        this.options = $.extend({}, this.options, options);

        /**
         * Unique Object Instance ID consist from his name and id
         *
         * @expose
         *
         * @type {string}
         */
        this.uid = this.name + this.id;

        // initialize state object only if
        // we are not using this object prototype
        if (!is_prototype) {
            this.state = new this.State();
            refinery.Object.instances.add(this);
        }
    };

    refinery.Object.prototype = {

        /**
         * Id
         *
         * @expose
         * @private
         * @type {number}
         */
        id: 0,

        /**
         * Name
         *
         * @expose
         * @type {string}
         */
        name: 'Object',

        /**
         * Version
         *
         * @expose
         * @type {string}
         */
        version: '0.1',

        /**
         * Module
         *
         * @expose
         * @type {string}
         */
        module: 'refinery',

        /**
         * Options
         *
         * @expose
         * @type {?Object}
         */
        options: null,

        /**
         * Events
         *
         * @expose
         * @type {?Object}
         */
        events: null,

        /**
         * jQuery wrapper around DOM element
         *
         * @expose
         * @type {?jQuery}
         */
        holder: null,

        /**
         * Fullname
         *
         * @expose
         * @public
         *
         * @type {string}
         */
        fullname: 'refinery.Object',

        /**
         * State class instatiable via Object constructor
         * @expose
         * @lends {refinery.ObjectState}
         */
        State: refinery.ObjectState,

        /**
         * State instance
         *
         * @expose
         *
         * @type {?refinery.ObjectState}
         */
        state: null,

        /**
         * Check or set object state
         *
         * @expose
         * @param {string|Object} action
         * @param {boolean=} state
         *
         * @return {boolean|undefined}
         */
        is: function (action, state) {
            if (!this.state) {
                return;
            }

            if (typeof state === 'undefined' && typeof action !== 'object') {
                return this.state.is(action);
            }

            this.state.set(action, state);
        },

        /**
         * Register Callback on event
         * If callback return false none of other callback after that
         * will be executed
         *
         * @public
         * @expose
         * @param {string} eventName
         * @param {Function} callback
         *
         * @return {Object} this
         */
        on: function (eventName, callback) {
            var events = this.events || {};

            events[eventName] = events[eventName] || [];
            events[eventName].push(callback);
            this.events = events;

            return this;
        },

        /**
         * Remove Callback from event
         *
         * @public
         * @expose
         * @param {string} eventName
         * @param {Function} callback
         *
         * @return {Object} this
         */
        off: function (eventName, callback) {
            var events = this.events;

            if (events && events[eventName] && events[eventName] instanceof Array) {
                events[eventName].splice(events[eventName].indexOf(callback), 1);
            }

            return this;
        },

        /**
         * Register observer on object event
         *
         * @expose
         * @public
         *
         * @param {string} eventName
         * @param {Function} callback
         *
         * @return {Object} self
         */
        subscribe: function (eventName, callback) {
            // console.log(eventName, this.uid, 'subscribed');
            refinery.pubsub.subscribe(this.uid + '.' + eventName, callback);

            return this;
        },

        /**
         * Remove observer from object event
         *
         * @expose
         * @public
         *
         * @param {string} eventName
         * @param {Function} callback
         *
         * @return {Object} self
         */
        unsubscribe: function (eventName, callback) {
            refinery.pubsub.unsubscribe(this.uid + '.' + eventName, callback);

            return this;
        },

        /**
         * Call registered callbacks and publish event for object observers
         *
         * @expose
         * @private
         *
         * @param {string}      eventName
         * @param {Array=}    args
         *
         * @return {Object}
         */
        trigger: function (eventName, args) {
            var events = this.events, a, i;

            args = (typeof args !== 'undefined' && !(args instanceof Array)) ? [args] : args;

            if (events && events[eventName]) {
                for (a = events[eventName], i = a.length - 1; i >= 0; i--) {
                    if (a[i].apply(this, args) === false) {
                        break;
                    }
                }
            }

            refinery.pubsub.publish(this.uid + '.' + eventName, args);

            return this;
        },

        /**
         * Null object: unbind holder, null state, null events
         * Events are nulled after broadcasting 'destroy' event, because if someone is
         * listening this event/object then he must get chance to respond.
         *
         * @expose
         * @return {Object} self
         */
        destroy: function () {
            if (this.holder) {
                this.holder.unbind();
                this.detach_holder();
            }

            this.state = null;

            refinery.Object.instances.remove(this.uid);

            this.trigger('destroy');
            this.events = {};

            return this;
        },

        /**
         * Call refinery Object destroy method on prototype.
         * This is required especialy when we rewrite destroy method on
         * inherited object from refinery.Object
         *
         * @expose
         * @return {Object} self
         */
        _destroy: function () {
            return refinery.Object.prototype.destroy.apply(this, arguments);
        },

         /**
         * Attach refinery.Object to DOM object (this.holder)
         *
         * @expose
         * @param {!jQuery} holder jQuery wrapper around DOM object
         *
         * @return {undefined}
         */
        attach_holder: function (holder) {
            var data = /** @type {Array} */(holder.data('refinery-instances') || []);
            holder.data('refinery-instances', data.concat(this.uid));
            holder.addClass('refinery-instance');
            this.holder = holder;
        },

        /**
         * Remove refinery.Object Instance from DOM object (this.holder)
         *
         * @expose
         *
         * @return {undefined}
         */
        detach_holder: function () {
            var holder = this.holder,
                data = holder.data('refinery-instances') || [],
                uid = this.uid;

            holder.data('refinery-instances',
                data.filter(function (elm) {
                    return (elm !== uid);
                }));

            if (holder.data('refinery-instances').length === 0) {
                holder.removeClass('refinery-instance');
            }

            this.holder = null;
        },

        /**
         * Initialization and binding
         *
         * @public
         * @expose
         * @param {!jQuery} holder
         *
         * @return {refinery.Object} self
         */
        init: function (holder) {
            if (this.is('initialisable')) {
                this.holder = holder;
                this.is('initialised', true);
                this.trigger('init');
            }

            return this;
        }
    };

    /**
     * Incremental objects counter
     *
     * @type {number}
     */
    refinery.Object.guid = 0;

    /**
     * Refinery Object
     *
     * @expose
     *
     * @param {(Object|{objectPrototype: (Object|undefined),
     *                    objectConstructor: (undefined|function ((undefined|Object)): ?),
     *                    objectMethods: (Object|undefined),
     *                    name: (string|undefined),
     *                    version: (string|undefined),
     *                    module: (string|undefined),
     *                    options: (Object|undefined),
     *                    var_args})=} options
     *
     * @return {Object}
     */
    refinery.Object.create = function (options) {
        var MyObject,
            /** @type {string} */
            key,

            /**
             * Singleton/Class methods
             */
            object_methods,

            /**
             * Meta properties of created object
             * @type {Array}
             */
            intern_properties = ['objectPrototype', 'objectConstructor', 'objectMethods', 'id', 'uid'];

        options = options || {};
        object_methods = options['objectMethods'];

        /**
         * @constructor
         * @extends {refinery.Object}
         *
         * @param {Object=} options
         * @param {boolean=} is_prototype
         */
        MyObject = options['objectConstructor'] || function (options, is_prototype) {
            refinery.Object.call(this, options, is_prototype);
        };

        MyObject.prototype = options['objectPrototype'] || new refinery.Object(null, true);

        /** @expose */
        options.module = options.module ? 'refinery.' + options.module : MyObject.prototype.module;

        options.fullname = options.module + '.' + options.name;

        refinery.provide(options.fullname, MyObject);

        for (key in options) {
            if (options.hasOwnProperty(key) && intern_properties.indexOf(key) === -1) {
                MyObject.prototype[key] = options[key];
            }
        }

        if (object_methods) {
            for (key in object_methods) {
                if (object_methods.hasOwnProperty(key)) {
                    MyObject[key] = object_methods[key];
                }
            }
        }

        return MyObject;
    };

    /**
     * Remove refinery.Object Instance from DOM object (this.holder)
     *
     * @expose
     * @param {!jQuery} holder jQuery wrapper around DOM object
     *
     * @return {undefined}
     */
    refinery.Object.unbind = function (holder) {
        var instances = holder.data('refinery-instances', []),
            instance;

        for (var i = instances.length - 1; i >= 0; i--) {
            instance = refinery.Object.instances.get(instances[i]);
            if (instance) {
                instance.destroy(true);
            }
        }

        holder.removeClass('refinery-instance');
    };

    /**
     * refinery Object Instances
     *
     * @expose
     *
     * @type {Object}
     */
    refinery.Object.instances = (function () {

        /**
         * Hash of all refinery.Object instances
         *
         * @type {Object}
         */
        var instances = {};

        return {

            /**
             * Return all refinery.Object instances
             *
             * @return {Object}
             */
            all: function () {
                return instances;
            },

            /**
             * Add instance
             *
             * @expose
             * @param {Object} instance
             */
            add: function (instance) {
                instances[instance.uid] = instance;
            },

            /**
             * Get Instance by UID
             *
             * @expose
             * @param {string} uid
             * @return {Object|undefined}
             */
            get: function (uid) {
                return instances[uid];
            },

            /**
             * Remove instance by UID
             *
             * @expose
             * @param {string} uid
             */
            remove: function (uid) {
                delete instances[uid];
            }
        };
    }());
}(window, jQuery));