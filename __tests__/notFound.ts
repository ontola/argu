//@ts-check

const h1Selector = (role = 'heading'): 'h1' => 'h1[role="heading"]' as 'h1';

describe('not found', () => {
  it('handles non existing tenant domain', async () => {
    await page.goto('https://demogemeente.localtest/');

    const heading = await page.waitForSelector(h1Selector());
    const headingText = await heading.evaluate((el) => el.innerText);

    expect(headingText).toContain('This item is not found');
  });

  it('handles non existing tenant path', async () => {
    await page.goto('https://argu.localtest/wrong_tenant');

    const heading = await page.waitForSelector(h1Selector());
    const headingText = await heading.evaluate((el) => el.innerText);

    expect(headingText).toContain('This item is not found');
  });

  it('handles non existing resource path', async () => {
    await page.goto('https://argu.localtest/argu/nonexistent');

    const heading = await page.waitForSelector(h1Selector());
    const headingText = await heading.evaluate((el) => el.innerText);

    expect(headingText).toContain('This item is not found');
  });
});
