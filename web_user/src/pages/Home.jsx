import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Play, Info, Plus, ChevronRight, ChevronLeft, Star, Volume2, Maximize, RotateCcw } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Home = () => {
  const [sections, setSections] = useState([]);
  const [featured, setFeatured] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await api.get('/api/v1/home');
        const data = res.data;

        const sectionList = [
          { title: "Trending Now", movies: data.trendingMovies },
          { title: "Top Rated Collections", movies: data.topRatedMovies },
          { title: "Most Popular", movies: data.popularMovies },
          { title: "Must Watch Series", movies: data.trendingTV },
        ];

        setSections(sectionList.filter(s => s.movies && s.movies.length > 0));

        if (data.trendingMovies?.length > 0) {
          setFeatured(data.trendingMovies[0]);
        }
      } catch (err) {
        console.error("Error fetching home data:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  if (loading) return <HomeSkeleton />;

  return (
    <div className="min-h-screen bg-[#050505] pb-20">
      {/* Cinematic Hero */}
      {featured && (
        <section className="relative h-[110vh] w-full overflow-hidden flex items-center">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1 }}
            className="absolute inset-0 z-0"
          >
            <img
              src={featured.backdropUrl || featured.posterUrl}
              className="w-full h-full object-cover scale-105"
              alt=""
            />
            <div className="absolute inset-0 hero-gradient-bottom"></div>
            <div className="absolute inset-0 hero-gradient-left"></div>
          </motion.div>

          <div className="relative z-10 w-full px-6 md:px-16 pt-20">
             <motion.div
               initial={{ opacity: 0, y: 30 }}
               animate={{ opacity: 1, y: 0 }}
               transition={{ delay: 0.3, duration: 0.8 }}
               className="max-w-3xl"
             >
                <div className="flex items-center space-x-3 mb-8">
                    <span className="bg-white/10 backdrop-blur-md border border-white/10 px-4 py-1 rounded-full text-[10px] font-extrabold uppercase tracking-[0.2em]">Featured Release</span>
                    <div className="flex items-center text-yellow-400 font-black text-sm">
                        <Star size={16} fill="currentColor" className="mr-1.5" />
                        <span>{featured.rating?.toFixed(1) || '8.5'}</span>
                    </div>
                </div>

                <h1 className="text-7xl md:text-9xl font-black mb-8 leading-[0.85] tracking-tighter">
                  {featured.title.split(' ').map((word, i) => (
                    <span key={i} className={i % 2 === 0 ? 'text-white' : 'text-purple-600'}>{word} </span>
                  ))}
                </h1>

                <p className="text-lg md:text-xl text-slate-300 mb-12 line-clamp-3 font-medium max-w-xl leading-relaxed">
                  {featured.description}
                </p>

                <div className="flex flex-wrap items-center gap-6">
                  <button
                    onClick={() => navigate(`/watch/${featured._id || featured.id}`)}
                    className="flex items-center space-x-4 bg-white text-black px-12 py-5 rounded-2xl hover:bg-purple-600 hover:text-white transition-all duration-500 font-black uppercase tracking-widest shadow-[0_15px_40px_rgba(255,255,255,0.1)] hover:scale-105 active:scale-95"
                  >
                    <Play fill="currentColor" size={24} />
                    <span>Watch Now</span>
                  </button>
                  <button
                    onClick={() => navigate(`/movie/${featured._id || featured.id}`)}
                    className="flex items-center space-x-4 glass text-white px-10 py-5 rounded-2xl hover:bg-white/10 transition-all duration-500 font-black uppercase tracking-widest border border-white/10"
                  >
                    <Info size={24} />
                    <span>Details</span>
                  </button>
                </div>
             </motion.div>
          </div>
        </section>
      )}

      {/* Modern Horizontal Grids */}
      <div className="relative z-20 -mt-40 space-y-24">
        {sections.map((section, idx) => (
          <SectionRow key={idx} title={section.title} movies={section.movies} index={idx} />
        ))}
      </div>
    </div>
  );
};

const SectionRow = ({ title, movies, index }) => {
  const navigate = useNavigate();
  const rowRef = useRef(null);

  const slide = (direction) => {
    if (rowRef.current) {
      const { scrollLeft, clientWidth } = rowRef.current;
      const scrollTo = direction === 'left' ? scrollLeft - clientWidth : scrollLeft + clientWidth;
      rowRef.current.scrollTo({ left: scrollTo, behavior: 'smooth' });
    }
  };

  return (
    <div className="px-6 md:px-16 overflow-hidden">
      <div className="flex items-end justify-between mb-8">
        <h2 className="text-2xl md:text-4xl font-black text-white/90 tracking-tighter">
          {title}
        </h2>
        <div className="flex space-x-3">
           <button onClick={() => slide('left')} className="p-3 bg-white/5 rounded-2xl hover:bg-purple-600 transition-all border border-white/5">
              <ChevronLeft size={20} />
           </button>
           <button onClick={() => slide('right')} className="p-3 bg-white/5 rounded-2xl hover:bg-purple-600 transition-all border border-white/5">
              <ChevronRight size={20} />
           </button>
        </div>
      </div>

      <div
        ref={rowRef}
        className="flex space-x-6 overflow-x-scroll scrollbar-hide pb-10"
        style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
      >
        {movies.map((movie) => (
          <motion.div
            key={movie._id || movie.id}
            whileHover={{ y: -15 }}
            onClick={() => navigate(`/movie/${movie._id || movie.id}`)}
            className="flex-none w-48 md:w-80 group cursor-pointer"
          >
            <div className="relative aspect-[2/3] md:aspect-video rounded-[1.5rem] overflow-hidden shadow-2xl border border-white/5 transition-all duration-500 group-hover:border-purple-600 group-hover:shadow-[0_0_50px_rgba(139,92,246,0.3)]">
               <img
                src={movie.posterUrl}
                className="w-full h-full object-cover transition-transform duration-1000 group-hover:scale-110"
                alt=""
                loading="lazy"
              />

              <div className="absolute inset-0 bg-black/80 opacity-0 group-hover:opacity-100 transition-all duration-500 flex flex-col justify-end p-6 backdrop-blur-md">
                  <div className="flex items-center space-x-2 mb-3">
                      <div className="bg-purple-600 px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-widest">Ultra HD</div>
                      <div className="flex items-center text-yellow-400 text-[10px] font-bold">
                        <Star size={12} fill="currentColor" className="mr-1" />
                        <span>{movie.rating?.toFixed(1) || '8.5'}</span>
                      </div>
                  </div>
                  <h3 className="font-black text-lg mb-2 uppercase leading-tight line-clamp-1">{movie.title}</h3>
                  <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mb-5">{movie.year} • Action • Sci-Fi</p>

                  <div className="flex space-x-3">
                    <button className="flex-1 bg-white text-black py-3 rounded-xl font-black uppercase tracking-widest text-[9px] hover:bg-purple-600 hover:text-white transition-all">Play</button>
                    <button className="p-3 bg-white/10 rounded-xl hover:bg-white/20 transition-all">
                        <Plus size={18} />
                    </button>
                  </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
};

const HomeSkeleton = () => (
    <div className="h-screen bg-[#050505] p-16 space-y-12">
        <div className="h-2/3 w-full skeleton rounded-[3rem]"></div>
        <div className="flex space-x-8 overflow-hidden">
            {[1, 2, 3, 4].map(i => <div key={i} className="flex-none w-80 aspect-video skeleton rounded-3xl"></div>)}
        </div>
    </div>
);

export default Home;
