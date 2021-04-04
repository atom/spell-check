// To avoid increasing the startup time and not loading modules that aren't
// required, we use a thin wrapper around the `debug` logging library that
// allows us to configure it via the Atom settings.

let enabled = atom.config.get('spell-check.enableDebug');
let loggers = {};

function updateLocalStorage() {
    // If we aren't enabled, we do nothing.
    if (!enabled) {
        return;
    }

    // `debug` requires `localStorage.debug` to contain the prefix for keys.
    // Because we have a configuration, we make sure they are there to avoid
    // a second step to enabling logging. We only check for the presence of
    // *any* spell-check reference so the user can customize it without worrying
    // about it being overridden.
    if (localStorage.debug === undefined) {
        localStorage.debug = '';
    }

    if (localStorage.debug.indexOf('spell-check') < 0) {
        let keys = localStorage.debug.split(',').filter((x) => x !== '');
        keys.push('spell-check');
        keys.push('spell-check:*');
        localStorage.debug = keys.join(',');
    }
}

/**
 * Updates the registered loggers along with the new one to use `debug` instead
 * of the internal, null sink.
 */
function update() {
    // If we aren't enabled, then don't do anything.
    enabled = atom.config.get('spell-check.enableDebug');

    // Go through all the existing loggers and rebind or set them up using the
    // new settings.
    for (const scope in loggers) {
        if (loggers.hasOwnProperty(scope)) {
            // Pull out the current logger and make sure it is properly enabled.
            let config = loggers[scope];

            config.wrapper.enabled = enabled;

            // If we are enabled, then load `debug` and use that to create a
            // proper log sink using that package.
            if (enabled) {
                const debug = require('debug');

                config.sink = debug(scope);
                config.sink.log = console.log.bind(console);
            }
        }
    }

    // Make sure the local storage keys.
    updateLocalStorage();
}

/**
 * Creates a logger based on the atom settings. If the user has enabled logging
 * for spell-check, then this also ensures that the spell-check entries will be
 * added to localStorage for debugging.
 *
 * @param {string} scope The name of the scope, such as "spell-check" or
                        "spell-check:locale-checker:en-US".
 * @returns A lambda that is either does nothing or it is the full debug call.
 */
function create(scope) {
    // See if we already have a logger defined for this value.
    if (loggers[scope] !== undefined) {
        return loggers[scope].wrapper;
    }

    // We use a logger object to contain all the variables and components of
    // a log at each level. We do this so we can turn logging on or after based
    // on editor settings.
    let config = {
        scope: scope,
        sink: undefined,
    };

    // If we are enabled, then we've already loaded the `debug` module.
    if (enabled) {
        const debug = require('debug');
        config.sink = debug(scope);
        config.sink.log = console.log.bind(console);
    }

    // Create the function that will actually perform the logging. This function
    // uses the `arguments` property to pass values into the inner logger.
    config.wrapper = function () {
        if (config.sink !== undefined) {
            config.sink.apply(config.sink, arguments);
        }
    };

    /**
     * The `extend` method is used to create a new logger with a ":" between the
     * old scope and the new one.
     *
     * @param {string} newScope The name of the inner scope to extend.
     * @returns The logging function.
     */
    config.extend = function (newScope) {
        return create([scope, newScope].join(':'));
    };

    // Wrap everything into the wrapper so it acts like `debug`.
    config.wrapper.config = config;
    config.wrapper.extend = config.extend;
    config.wrapper.update = update;
    config.wrapper.enabled = enabled;

    // Cache the loggers for updating later and return it.
    loggers[scope] = config;

    return config.wrapper;
}

/**
 * Creates the root logger.
 */
function createRoot() {
    return create('spell-check');
}

// Set up the first-time calls.
updateLocalStorage();

module.exports = createRoot;
