import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import api from '../utils/api';
import { ArrowLeft, Play, Pause, Volume2, Maximize, Settings, RotateCcw, RotateCw, Monitor, Subtitles } from 'lucide-react';

const Player = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const season = queryParams.get('s');
  const episode = queryParams.get('e');

  const [movie, setMovie] = useState(null);
  const [sources, setSources] = useState([]);
  const [subtitles, setSubtitles] = useState([]);
  const [selectedSource, setSelectedSource] = useState(null);
  const [selectedSubtitle, setSelectedSubtitle] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [showControls, setShowControls] = useState(true);
  const [showSourceSelector, setShowSourceSelector] = useState(false);
  const [showSubtitleSelector, setShowSubtitleSelector] = useState(false);
  const videoRef = useRef(null);
  const controlsTimerRef = useRef(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const movieRes = await api.get(`/movies/${id}`);
        setMovie(movieRes.data);

        let sourcesUrl = `/api/v1/movie/${id}/sources`;
        if (season && episode) {
          sourcesUrl = `/api/v1/tv/${id}/sources/${season}/${episode}`;
        }
        const response = await api.get(sourcesUrl);
        const sourcesData = response.data.sources || [];
        const subtitlesData = response.data.subtitles || [];

        setSources(sourcesData);
        setSubtitles(subtitlesData);

        if (sourcesData.length > 0) {
          setSelectedSource(sourcesData[0]);
        }
      } catch (err) {
        console.error(err);
      }
    };
    fetchData();
  }, [id, season, episode]);

  const handleMouseMove = () => {
    setShowControls(true);
    if (controlsTimerRef.current) clearTimeout(controlsTimerRef.current);
    controlsTimerRef.current = setTimeout(() => {
      if (isPlaying) setShowControls(false);
    }, 3000);
  };

  const togglePlay = () => {
    if (!videoRef.current) return;
    if (videoRef.current.paused) {
      videoRef.current.play();
      setIsPlaying(true);
    } else {
      videoRef.current.pause();
      setIsPlaying(false);
    }
  };

  const onTimeUpdate = () => {
    if (videoRef.current) {
      setProgress((videoRef.current.currentTime / videoRef.current.duration) * 100);
    }
  };

  const onLoadedMetadata = () => {
    if (videoRef.current) {
      setDuration(videoRef.current.duration);
    }
  };

  const handleSeek = (e) => {
    if (!videoRef.current) return;
    const seekTime = (e.target.value / 100) * videoRef.current.duration;
    videoRef.current.currentTime = seekTime;
    setProgress(e.target.value);
  };

  const formatTime = (time) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
  };

  if (!movie) return <div className="h-screen bg-black flex items-center justify-center font-bold text-purple-500 animate-pulse">Initializing Player...</div>;

  const isEmbed = selectedSource?.type === 'embed';

  return (
    <div
      className="fixed inset-0 z-[100] bg-black group overflow-hidden"
      onMouseMove={handleMouseMove}
    >
      {/* Back Button */}
      <div className={`absolute top-0 left-0 p-8 z-[110] transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0'}`}>
        <button
          onClick={() => navigate(-1)}
          className="flex items-center space-x-3 text-white hover:text-purple-400 font-black uppercase tracking-tighter text-xl italic"
        >
          <ArrowLeft size={32} />
          <span>{movie.title} {season && ` - S${season}E${episode}`}</span>
        </button>
      </div>

      {/* Video Content */}
      <div className="w-full h-full">
        {isEmbed ? (
          <iframe
            src={selectedSource.url}
            className="w-full h-full border-none"
            allowFullScreen
            title="Video Player"
          />
        ) : (
          <video
            ref={videoRef}
            src={selectedSource?.url || movie.videoUrl}
            className="w-full h-full cursor-none"
            onTimeUpdate={onTimeUpdate}
            onLoadedMetadata={onLoadedMetadata}
            onClick={togglePlay}
            autoPlay
          >
            {selectedSubtitle && (
              <track
                label={selectedSubtitle.language}
                kind="subtitles"
                srcLang="en"
                src={selectedSubtitle.url}
                default
              />
            )}
          </video>
        )}
      </div>

      {/* Controls Overlay (Only for non-embed) */}
      {!isEmbed && (
        <div className={`absolute inset-0 bg-gradient-to-t from-black via-transparent to-black/40 flex flex-col justify-end p-8 transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0'}`}>

          {/* Progress Bar */}
          <div className="w-full mb-8">
            <input
              type="range"
              min="0"
              max="100"
              value={progress}
              onChange={handleSeek}
              className="w-full h-1.5 bg-white/20 rounded-full appearance-none cursor-pointer accent-purple-600 hover:h-2.5 transition-all"
            />
            <div className="flex justify-between text-sm mt-3 font-black font-mono text-white/70 tracking-widest">
              <span>{formatTime(videoRef.current?.currentTime || 0)}</span>
              <span>{formatTime(duration)}</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-10">
              <button onClick={togglePlay} className="text-white hover:scale-125 transition-transform">
                {isPlaying ? <Pause size={48} fill="white" /> : <Play size={48} fill="white" />}
              </button>
              <div className="flex items-center space-x-6">
                <button onClick={() => videoRef.current.currentTime -= 10} className="text-white/80 hover:text-white hover:scale-110 transition-all">
                  <RotateCcw size={32} />
                </button>
                <button onClick={() => videoRef.current.currentTime += 10} className="text-white/80 hover:text-white hover:scale-110 transition-all">
                  <RotateCw size={32} />
                </button>
              </div>
              <div className="flex items-center space-x-4 group/vol">
                 <Volume2 size={28} className="text-white/80" />
                 <input type="range" className="w-0 group-hover/vol:w-24 transition-all accent-purple-500 h-1.5 appearance-none bg-white/20 rounded-full" />
              </div>
            </div>

            <div className="flex items-center space-x-8">
              <button
                onClick={() => setShowSubtitleSelector(true)}
                className={`flex items-center space-x-2 transition-colors ${selectedSubtitle ? 'text-purple-400' : 'text-white/80 hover:text-white'}`}
              >
                <Subtitles size={28} />
                <span className="text-sm font-black uppercase tracking-widest">{selectedSubtitle?.language || 'Off'}</span>
              </button>

              <button
                onClick={() => setShowSourceSelector(true)}
                className="text-white hover:text-purple-400 flex items-center space-x-3 bg-white/5 px-4 py-2 rounded-xl border border-white/10 hover:border-purple-500/50 transition-all"
              >
                <Monitor size={24} />
                <span className="text-sm font-black uppercase tracking-widest">{selectedSource?.label || 'Server'}</span>
              </button>

              <button
                onClick={() => videoRef.current.requestFullscreen()}
                className="text-white/80 hover:text-white hover:scale-110 transition-transform"
              >
                <Maximize size={28} />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Floating Source Selector (For embed mode) */}
      {isEmbed && showControls && (
          <div className="absolute bottom-8 right-8 z-[120] flex space-x-4">
             <button
                onClick={() => setShowSourceSelector(true)}
                className="bg-purple-600 text-white px-6 py-3 rounded-2xl font-black uppercase tracking-widest flex items-center space-x-3 hover:bg-purple-700 transition-all shadow-2xl scale-110"
              >
                <Monitor size={24} />
                <span>Switch Server</span>
              </button>
          </div>
      )}

      {/* Fullscreen Selection Overlays */}
      {showSourceSelector && (
        <SelectionOverlay
          title="Select Streaming Server"
          items={sources}
          selectedItem={selectedSource}
          onSelect={(item) => {
            setSelectedSource(item);
            setShowSourceSelector(false);
          }}
          onClose={() => setShowSourceSelector(false)}
          renderItem={(source) => (
            <>
               <div className="text-white font-black text-2xl mb-1">{source.label}</div>
               <div className="text-zinc-400 text-xs font-bold uppercase tracking-[0.2em]">{source.quality} • {source.provider}</div>
            </>
          )}
        />
      )}

      {showSubtitleSelector && (
        <SelectionOverlay
          title="Subtitles"
          items={[{language: 'Off'}, ...subtitles]}
          selectedItem={selectedSubtitle || {language: 'Off'}}
          onSelect={(item) => {
            setSelectedSubtitle(item.language === 'Off' ? null : item);
            setShowSubtitleSelector(false);
          }}
          onClose={() => setShowSubtitleSelector(false)}
          renderItem={(sub) => (
            <div className="text-white font-black text-2xl py-2">{sub.language}</div>
          )}
        />
      )}
    </div>
  );
};

const SelectionOverlay = ({ title, items, selectedItem, onSelect, onClose, renderItem }) => (
  <div className="absolute inset-0 bg-black/95 z-[200] flex items-center justify-center p-8 backdrop-blur-sm">
    <div className="max-w-4xl w-full">
      <div className="flex justify-between items-end mb-12 border-b-4 border-purple-600 pb-4">
        <h2 className="text-5xl font-black text-white italic uppercase tracking-tighter">{title}</h2>
        <button onClick={onClose} className="text-zinc-500 hover:text-white transition-colors">
          <Maximize size={32} className="rotate-45" />
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-h-[60vh] overflow-y-auto pr-4 custom-scrollbar">
        {items.map((item, index) => (
          <button
            key={index}
            onClick={() => onSelect(item)}
            className={`p-8 rounded-3xl text-left transition-all transform hover:scale-[1.02] ${
              (selectedItem?.label === item.label || selectedItem?.language === item.language)
              ? 'bg-purple-600 shadow-[0_0_40px_rgba(147,51,234,0.3)] ring-4 ring-white'
              : 'bg-zinc-900/50 border-2 border-white/5 hover:border-purple-500/50 hover:bg-zinc-800'
            }`}
          >
            {renderItem(item)}
          </button>
        ))}
      </div>
      <button
        onClick={onClose}
        className="mt-12 text-zinc-500 hover:text-white font-black uppercase tracking-[0.3em] text-sm block mx-auto transition-colors"
      >
        Dismiss
      </button>
    </div>
  </div>
);

export default Player;
