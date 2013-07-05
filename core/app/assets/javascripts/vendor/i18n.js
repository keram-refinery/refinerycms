/*global window, $ */
(function (window) {
    'use strict';

    // very naive temporary i18n implementation
    // #todo rewrite/implement
    //
    var i18n = {
        messages: {},
        /**
         * @expose
         * @param  {object} keys json like object
         */
        register: function (keys, namespace) {
            if (typeof namespace === 'string') {
                i18n.messages[namespace] = i18n.messages[namespace] || {};
                $.extend(i18n.messages[namespace], keys);
            } else {
                $.extend(i18n.messages, keys);
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
                str = 'Translation Missing: ' +
                    (typeof namespace === 'string' ? namespace + '.' : '') +
                    key;

                if (typeof console === 'object') {
                    console.log(str);
                }
            }

            return str;
        }
    };

    window.t = i18n.localise;
    window.i18n = i18n;

}(window));