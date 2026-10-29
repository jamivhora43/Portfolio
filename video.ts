export type VideoProvider = 'youtube' | 'youtube_short' | 'vimeo' | 'mp4';
export interface ParsedVideo { provider: VideoProvider; embedUrl: string; thumbnail?: string; portrait: boolean }

const YT_HOSTS = new Set(['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be']);
const ID = /^[A-Za-z0-9_-]{11}$/;

// Strict allowlist: anything unrecognised returns null and is never embedded.
export function parseVideoUrl(raw: string): ParsedVideo | null {
  let u: URL;
  try { u = new URL(raw.trim()); } catch { return null; }
  if (u.protocol !== 'https:') return null;
  const host = u.hostname.toLowerCase();

  if (YT_HOSTS.has(host)) {
    let id: string | null = null, short = false;
    if (host === 'youtu.be') id = u.pathname.slice(1);
    else if (u.pathname === '/watch') id = u.searchParams.get('v');
    else if (u.pathname.startsWith('/shorts/')) { id = u.pathname.split('/')[2]; short = true; }
    else if (u.pathname.startsWith('/embed/')) id = u.pathname.split('/')[2];
    if (!id || !ID.test(id)) return null;
    return {
      provider: short ? 'youtube_short' : 'youtube',
      embedUrl: `https://www.youtube-nocookie.com/embed/${id}?rel=0`,
      thumbnail: `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
      portrait: short,
    };
  }
  if (host === 'vimeo.com' || host === 'www.vimeo.com' || host === 'player.vimeo.com') {
    const id = u.pathname.split('/').filter(Boolean).pop();
    if (!id || !/^\d+$/.test(id)) return null;
    return { provider: 'vimeo', embedUrl: `https://player.vimeo.com/video/${id}`, portrait: false };
  }
  if (u.pathname.toLowerCase().endsWith('.mp4')) {
    return { provider: 'mp4', embedUrl: u.toString(), portrait: false };
  }
  return null;
}
