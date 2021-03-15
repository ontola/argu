module.exports = {
  // preset: "jest-playwright-preset",
  testEnvironmentOptions: {
    "jest-playwright": {
      // browsers: ["chromium", "firefox", "webkit"],
      contextOptions: {
        ignoreHTTPSErrors: true,
        args: [
          '--host-resolver-rules="MAP 127.0.0.1 argu.localdev, MAP 127.0.0.1 demogemeente.localdev"',
        ],
      },
    },
  },
};
