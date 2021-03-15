//@ts-check
const { chromium } = require('playwright');

let browserName = 'chromium';
let browser;
let page;

beforeAll(async () => {
  browser = await chromium.launch({
    ignoreHTTPSErrors: true,
    proxy: {
      server: "socks5://127.0.0.1:55555"
    },
  });
});

beforeEach(async () => {
  page = await browser.newPage();
});

afterEach(async () => {
  await page.close();
});

afterAll(async () => {
  console.log('closing browser');
  await browser.close();
  console.log('closed browser');
});

test('should display correct browser before', async () => {
  await page.goto('https://whatismybrowser.com/')
  const browser = await page.$eval('.string-major', (el) => el.innerHTML);
  console.log(browser.toString());
  expect(browser).toContain('Chrome');
}, 20000);

test('custom browser test argu.localdev', async () => {
  await page.goto('https://argu.localdev/');
  await page.screenshot({ path: `example.png` });
  const element = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  expect(element).toContain('Argu');
}, 20000);

test('custom browser test demogemeente.localdev', async () => {
  await page.goto('https://demogemeente.localdev/');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/demogemeente-test-0.png` });
  const element = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/demogemeente-test-1.png` });
  expect(element).toContain('Demo Gemeente');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/demogemeente-test-2.png` });
}, 20000);

test('demogemeente.localdev home has a title', async () => {
  await page.goto('https://demogemeente.localdev/');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/home-${browserName}.png` });
  const browser = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  expect(browser).toContain('Demo Gemeente');
});

test('demogemeente.nl home has a title', async () => {
  await page.goto('https://demogemeente.nl/');
  await page.screenshot({ path: `${process.env['CI_PROJECT_DIR']}/test-results/home-${browserName}.png` });
  const browser = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
  expect(browser).toContain('Demo Gemeente');
});
