module.exports = {
  preset: "jest-playwright-preset",
  testEnvironmentOptions: {
    "jest-playwright": {
      // browsers: ["chromium", "firefox", "webkit"],
      launchOptions: {
        args: [
          '--host-resolver-rules="MAP 127.0.0.1 argu.localdev, MAP 127.0.0.1 demogemeente.localdev, MAP 127.0.0.1 argu.localtest, MAP 127.0.0.1 demogemeente.localtest"',
        ],
      },
      contextOptions: {
        ignoreHTTPSErrors: true,
        recordVideo: {
          dir: '/builds/ontola/core/test-results/video',
          size: { width: 1024, height: 768 },
        }
      },
    },
  },
};
