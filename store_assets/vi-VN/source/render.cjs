const { chromium } = require('/Volumes/sontc/sources/Tools/dashboard-flow/node_modules/playwright');
const path = require('node:path');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({headless:true,args:['--allow-file-access-from-files']});
  const page = await browser.newPage({viewport:{width:1100,height:2000},deviceScaleFactor:1});
  await page.goto('file://' + path.join(__dirname,'artboards.html'));
  await page.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(img=>img.decode()));});
  for(let i=1;i<=6;i++) {
    const target=page.locator('#phone-'+i);
    assert.equal(await target.locator('img').evaluate(img=>img.naturalWidth),1080);
    await target.screenshot({path:path.join(__dirname,'../phone',String(i).padStart(2,'0')+'.png')});
  }
  await page.locator('#feature').screenshot({path:path.join(__dirname,'../feature-graphic-1024x500.png')});
  const icon = await page.locator('#icon img').evaluate(img => { const canvas=document.createElement('canvas'); canvas.width=512; canvas.height=512; canvas.getContext('2d').drawImage(img,0,0,512,512); return canvas.toDataURL('image/png').split(',')[1]; });
  require('node:fs').writeFileSync(path.join(__dirname,'../icon-512.png'),Buffer.from(icon,'base64'));
  await page.setViewportSize({width:900,height:1020});
  await page.goto('file://' + path.join(__dirname,'preview.html'));
  await page.locator('img').last().waitFor();
  await page.evaluate(async()=>Promise.all([...document.images].map(img=>img.decode())));
  await page.screenshot({path:path.join(__dirname,'../preview.png'),fullPage:true});
  await browser.close();
})();
