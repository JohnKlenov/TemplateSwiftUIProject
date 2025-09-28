module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2021,
  },
  extends: [
    'eslint:recommended',
    'google',
  ],
  rules: {
    'max-len': 'off',
    'object-curly-spacing': 'off',
    'require-jsdoc': 'off',
    'indent': 'off',
    'comma-dangle': 'off'
  },
};
