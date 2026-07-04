import edge_tts
from aiohttp import web


async def synthesize(request):
    text = (request.query.get('text') or '').strip()
    voice = request.query.get('voice') or 'zh-CN-XiaoxiaoNeural'
    rate = request.query.get('rate') or '+0%'
    if not text:
        return web.Response(status=400, text='missing text')
    if len(text) > 500:
        return web.Response(status=400, text='text too long')
    try:
        communicate = edge_tts.Communicate(text, voice, rate=rate)
        buf = bytearray()
        async for chunk in communicate.stream():
            if chunk['type'] == 'audio':
                buf.extend(chunk['data'])
        if not buf:
            return web.Response(status=502, text='empty audio')
        return web.Response(body=bytes(buf), content_type='audio/mpeg')
    except Exception as e:
        return web.Response(status=502, text=f'tts failed: {e}')


async def health(_request):
    return web.Response(text='ok')


app = web.Application()
app.router.add_get('/synthesize', synthesize)
app.router.add_get('/health', health)
if __name__ == '__main__':
    web.run_app(app, host='0.0.0.0', port=5002)
