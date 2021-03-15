//@ts-check
const { chromium } = require('playwright');

let browserName = 'chromium';
let browser;
let page;

beforeAll(async () => {
  browser = await chromium.launch({
    ignoreHTTPSErrors: true,
    proxy: {
      server: "socks5://127.0.0.1:55556"
    },
  });
});

beforeEach(async () => {
  page = await browser.newPage({
    ignoreHTTPSErrors: true,
  });
});

afterEach(async () => {
  await page.close();
});

afterAll(async () => {
  await browser.close();
});

test('0 - demogemeente.localtest home has a title', async () => {
  await page.goto('https://demogemeente.localtest/');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/demogemeente-localtest-home-${browserName}.png` });
  const browser = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  expect(browser).toContain('Demo Gemeente');
}, 20000);

test('0 - Freetown home has a title', async () => {
  await page.goto('https://argu.localtest/argu/freetown');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/argu-localtest-home-${browserName}.png` });
  const browser = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  expect(browser).toContain('Freetown');
}, 20000);

test('demogemeente.nl home has a title', async () => {
  await page.goto('https://demogemeente.nl/');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/demogemeente-nl-home-${browserName}.png` });
  const browser = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  expect(browser).toContain('Demo Gemeente');
});
