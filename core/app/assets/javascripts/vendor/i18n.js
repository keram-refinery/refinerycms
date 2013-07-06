/*global window */
(function (window) {
    'use strict';

    // very naive "temporary" i18n implementation
    window.i18n = {
        messages: {},
        /**
         * @expose
         * @param  {object} keys json like object
         */
        register: function (keys, namespace) {
            var key;

            if (typeof namespace === 'string') {
                i18n.messages[namespace] = i18n.messages[namespace] || {};
                for (key in keys) {
                    i18n.messages[namespace][key] = keys[key];
                }
            } else {
                for (key in keys) {
                    i18n.messages[namespace][key] = keys[key];
                }
            }
        },

        localise: function (string, args) {
            var str, k, messages,
                path = string.split('.'),
                key = path.pop(),
                namespace = path.join('.');

            messages = i18n.messages[namespace] || i18n.messages;

            if (typeof messages[key] === 'string') {
                str = messages[key];
                if (typeof args === 'object') {
                    for (k in args) {
                        if (args.hasOwnProperty(k)) {
                            str = str.replace('{' + k + '}', args[k]);
                        }
                    }
                }
            } else {
                str = 'Translation Missing: ';
                str += (typeof namespace === 'string' ? namespace + '.' : '');
                str += key;

                if (typeof console === 'object') {
                    console.log(str);
                }
            }

            return str;
        }
    };

    window.t = i18n.localise;

}(window));
