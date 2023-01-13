"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRequestConfig = exports.Location_ = void 0;
var Location_;
(function (Location_) {
    Location_[Location_["Inline"] = 0] = "Inline";
    Location_[Location_["Offchain"] = 1] = "Offchain";
})(Location_ = exports.Location_ || (exports.Location_ = {}));
var CodeLanguage;
(function (CodeLanguage) {
    CodeLanguage[CodeLanguage["JavaScript"] = 0] = "JavaScript";
})(CodeLanguage || (CodeLanguage = {}));
const getRequestConfig = (unvalidatedConfig) => {
    const config = unvalidatedConfig;
    if (config.codeLocation !== Location_.Inline) {
        throw Error('codeLocation is not correctly specified in config file');
    }
    if (config.codeLanguage !== CodeLanguage.JavaScript) {
        throw Error('codeLanguage is not correctly specified in config file');
    }
    if (typeof config.source !== 'string') {
        throw Error('source is not correctly specified in config file');
    }
    if (config.numAllowedQueries) {
        if (typeof config.numAllowedQueries !== 'number' ||
            !Number.isInteger(config.numAllowedQueries)) {
            throw Error('numAllowedQueries is not correctly specified in config file');
        }
    }
    if (config.secrets || config.secretsURLs && config.secretsURLs.length > 0) {
        if (config.secretsLocation !== Location_.Inline
            && config.secretsLocation !== Location_.Offchain) {
            throw Error('secretsLocation is not correctly specified in config file');
        }
        if (config.secretsLocation === Location_.Inline && typeof config.secrets !== 'object') {
            throw Error('secrets object is not correctly specified in config file');
        }
        if (config.secretsLocation === Location_.Offchain) {
            if (!Array.isArray(config.secretsURLs)) {
                throw Error('secretsURLs array is not correctly specified in config file');
            }
            config.secretsURLs.forEach((s) => {
                if (s.slice(0, 8) !== 'https://' && s.slice(0, 7) !== 'http://') {
                    throw Error('invalid URL in secretsURLs (ensure all URLs are preceeded with "http://" or "https://")');
                }
            });
        }
        if (typeof config.walletPrivateKey !== 'string') {
            throw Error('walletPrivateKey is not correctly specified in config file');
        }
        if (config.DONPublicKey && typeof config.DONPublicKey !== 'string') {
            throw Error('DONPublicKey is not correctly specified in config file');
        }
    }
    if (config.args) {
        if (!Array.isArray(config.args))
            throw Error('args array is not correctly specified in config file');
        for (const arg of config.args) {
            if (typeof arg !== 'string') {
                throw Error('an element of the args array is not a string in config file');
            }
        }
    }
    if (config.maxResponseBytes) {
        if (typeof config.maxResponseBytes !== 'number' ||
            !Number.isInteger(config.maxResponseBytes)) {
            throw Error('maxResponseBytes is not correctly specified in config file');
        }
    }
    if (config.expectedReturnType) {
        if (typeof config.expectedReturnType !== 'string') {
            throw Error('expectedReturnType is not correctly specified in config file');
        }
        switch (config.expectedReturnType) {
            case 'uint256':
            case 'int256':
            case 'string':
            case 'Buffer':
                break;
            default:
                throw Error('expectedReturnType is not correctly specified in config file');
        }
    }
    return config;
};
exports.getRequestConfig = getRequestConfig;
