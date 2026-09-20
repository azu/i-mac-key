import Foundation

enum RemotePage {
    static let html = """
    <!doctype html><html lang="ja"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"><title>i-mac-key</title>
    <style>body{margin:0;background:#111;color:#fff;font:16px -apple-system,sans-serif;touch-action:manipulation}main{height:100dvh;display:grid;grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(3,1fr);gap:8px;padding:8px;box-sizing:border-box}.key{border:0;border-radius:18px;background:#292929;color:#fff;font-size:clamp(20px,7vw,36px);font-weight:700}.key:active{background:#555}.hint{position:fixed;bottom:12px;left:0;right:0;text-align:center;font-size:12px;color:#aaa;pointer-events:none}</style>
    <main id="keys"></main><div class="hint">タップ / 0.5秒長押し</div>
    <script>const q=new URLSearchParams(location.search),token=q.get('token'),keys=document.querySelector('#keys');let config=[];
    async function send(cell,gesture){navigator.vibrate?.(12);fetch(`/trigger?token=${encodeURIComponent(token)}&cell=${cell}&gesture=${gesture}`,{cache:'no-store'}).catch(()=>{});}
    function render(){keys.replaceChildren(...config.map((c,i)=>{let b=document.createElement('button');let timeout,didHold=false;b.className='key';b.textContent=c.tap==='なし'?'—':c.tap;const begin=e=>{e.preventDefault();didHold=false;timeout=setTimeout(()=>{didHold=true;b.textContent=c.hold==='なし'?'—':c.hold;send(i,'hold');},500)};const end=e=>{e.preventDefault();clearTimeout(timeout);if(!didHold)send(i,'tap');setTimeout(()=>b.textContent=c.tap==='なし'?'—':c.tap,100)};b.addEventListener('pointerdown',begin);b.addEventListener('pointerup',end);b.addEventListener('pointercancel',()=>clearTimeout(timeout));return b}));}
    fetch(`/config?token=${encodeURIComponent(token)}`).then(r=>r.json()).then(x=>{config=x.cells;render()});</script></html>
    """
}
