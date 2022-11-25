import { expect } from 'chai';
import mock from 'mock-fs'
import sinon from 'sinon'
import {Category, Gatherer} from '../src/lib/gatherer/gatherer.js'

describe('Gatherer', () => { 
  let gatherer: Gatherer

  before(() => {
    mock({
      '/tmp/test-content': mock.load('./tests/fixtures', {lazy:false}),
    });
  });

  beforeEach(() => {
    gatherer = new Gatherer()
  });
  
  context('when loading basic content', () => {
    let result : Category | null;

    it('should load the content', async () => {
      result = await gatherer.gather('/tmp/test-content/basic');

      expect(result?.title).to.equal("Basics")
      expect(result?.weight).to.equal(10)
      expect(result?.run).to.be.true
      expect(result?.path).to.equal('/tmp/test-content/basic')
    });

    it('should parse root category', async () => {
        expect(result?.title).to.equal("Basics")
        expect(result?.weight).to.equal(10)
        expect(result?.run).to.be.true
    });

    it('should parse index page', async () => {
      const page = result?.pages[0]

      expect(page?.title).to.equal("Basics")
      expect(page?.weight).to.equal(1)
      expect(page?.file).to.equal('/tmp/test-content/basic/index.md')
      expect(page?.scripts.length).to.equal(9)
    });

    it('should parse basic script', async () => {
      const script = result?.pages[0]?.scripts[0]

      expect(script?.command).to.equal("command1")
      expect(script?.expectError).to.be.false
      expect(script?.lineNumber).to.equal(8)
      expect(script?.timeout).to.equal(120)
      expect(script?.hook).to.be.null
    });

    it('should handle script with timeout', async () => {
      const script = result?.pages[0]?.scripts[1]

      expect(script?.timeout).to.equal(10)
    });

    it('should handle script with expectError', async () => {
      const script = result?.pages[0]?.scripts[2]

      expect(script?.expectError).to.be.true
    });

    it('should handle script with hook', async () => {
      const script = result?.pages[0]?.scripts[3]

      expect(script?.hook).to.equal('example')
    });

    it('should handle script with multiLine', async () => {
      const script = result?.pages[0]?.scripts[4]

      expect(script?.command).to.equal('command1\ncommand2')
    });

    it('should handle script with wait', async () => {
      const script = result?.pages[0]?.scripts[5]

      expect(script?.wait).to.equal(30)
    });

    it('should handle script with multiple commands', async () => {
      const script = result?.pages[0]?.scripts[6]

      expect(script?.command).to.equal("command1\ncommand2")
    });

    it('should handle script with multiple lines', async () => {
      const script = result?.pages[0]?.scripts[7]

      expect(script?.command).to.equal("command1 \\\nline2 \\\nline3")
    });

    it('should handle script with heredoc', async () => {
      const script = result?.pages[0]?.scripts[8]

      expect(script?.command).to.equal("cat <<EOF > /tmp/yourfilehere\ncheck this\nEOF")
    });

    it('should sort pages with weight', async () => {
      const pageA = result?.pages[2]

      expect(pageA?.title).to.equal('Sorting - A')
    });

    it('should be recursive', async () => {
      const nestedCategory = result?.children[1]

      expect(nestedCategory?.title).to.equal('Nested')
    });
  })
  
  after(() => {
    mock.restore();
  });
});
