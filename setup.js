
beforeEach(async () => {
  const videoFileName = await page.video().path();

  console.log(`Test '${expect.getState().currentTestName}' has video ${videoFileName}`);
});
