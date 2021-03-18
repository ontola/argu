//@ts-check

const baseDir = `${process.env['CI_PROJECT_DIR'] ?? process.cwd()}/test-results`;
console.log(`Basedir: ${baseDir}`);
console.log(`cwd: ${process.cwd()}`);
console.log(`CI_PROJECT_DIR: ${process.env['CI_PROJECT_DIR']}`);
// let browserName = 'chromium';

// test('0 - demogemeente.localtest home has a title', async () => {
//   await page.goto('https://demogemeente.localtest/');
//   await page.screenshot({ path: `${baseDir}/demogemeente-localtest-home-${browserName}.png` });
//   const browser = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
//   expect(browser).toContain('Demo Gemeente');
// });

test('0 - Freetown home has a title', async () => {
  await page.goto('https://argu.localtest/argu/freetown');
  const heading = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  await page.screenshot({ path: `${baseDir}/freetown-home-title-${browserName}.png` });
  expect(heading).toContain('Freetown');
});
