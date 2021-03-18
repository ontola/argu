
describe('not found', () => {
  it('handles non existing tenant domain', async () => {
    await page.goto('https://demogemeente.localtest/');
    const heading = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
    expect(heading).toContain('This item is not found');
  });

  it('handles non existing tenant path', async () => {
    await page.goto('https://argu.localtest/wrong_tenant');
    const heading = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
    expect(heading).toContain('This item is not found');
  });

  it('handles non existing resource path', async () => {
    await page.goto('https://argu.localtest/argu/nonexistent');
    const heading = await page.$eval('h1[role="heading"]', (el) => el.innerHTML);
    expect(heading).toContain('This item is not found');
  });
});
