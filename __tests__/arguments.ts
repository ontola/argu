const baseDir = `${process.env['CI_PROJECT_DIR'] ?? process.cwd()}/test-results`;

const goToParent = () => {};

const fillInOmniform = (omniform_parent: string, click_to_open: boolean = false, side: string = 'pro') => {

}

const postArgument = async () => {
  // goToParent('.FullResource div:nth-child(1) div.Card')
  // fillInOmniform(parent, true);
}

describe('arguments', () => {
  const location = 'https://argu.localtest/argu/argu/m/38';

  describe('as guest', () => {
    test('', async () => {
      await page.goto('https://argu.localtest/argu/freetown');

      const heading = await page.waitForSelector('h1[role="heading"]');
      const headingText = await heading.evaluate( (el) => el.textContent);

      expect(headingText).toContain('Freetown');
    });
  });
});
