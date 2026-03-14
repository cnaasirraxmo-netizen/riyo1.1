import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Play, Info, Plus, ChevronRight, ChevronLeft, Star, Clock } from 'lucide-react';
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
          { title: "Trending Movies", movies: data.trendingMovies },
          { title: "Popular Choices", movies: data.popularMovies },
          { title: "Top Rated", movies: data.topRatedMovies },
          { title: "Trending TV Shows", movies: data.trendingTV },
        ];

        setSections(sectionList.filter(s => s.movies && s.movies.length > 0));

        if (data.trendingMovies?.length > 0) {
          setFeatured(data.trendingMovies[0]);
        } else if (data.popularMovies?.length > 0) {
          setFeatured(data.popularMovies[0]);
        }
      } catch (err) {
        console.error("Error fetching home data:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  if (loading) return (
    <div className="h-screen flex flex-col items-center justify-center bg-[#0a0a0a]">
      <div className="w-16 h-16 border-t-4 border-purple-600 border-solid rounded-full animate-spin mb-4"></div>
      <div className="text-purple-500 font-black tracking-widest animate-pulse italic uppercase">Syncing Library...</div>
    </div>
  );

  return (
    <div className="min-h-screen bg-[#0a0a0a] text-white selection:bg-purple-600 selection:text-white">
      {/* Dynamic Hero Section */}
      {featured && (
        <section className="relative h-screen w-full overflow-hidden">
          <motion.div
            initial={{ opacity: 0, scale: 1.1 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1.5 }}
            className="absolute inset-0"
          >
            <img
              src={featured.backdropUrl || featured.posterUrl}
              className="w-full h-full object-cover brightness-[0.6]"
              alt={featured.title}
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[#0a0a0a] via-transparent to-transparent"></div>
            <div className="absolute inset-0 bg-gradient-to-r from-[#0a0a0a] via-[#0a0a0a]/30 to-transparent"></div>
          </motion.div>

          <div className="absolute bottom-0 left-0 w-full p-6 md:p-20 z-10">
             <motion.div
               initial={{ opacity: 0, x: -50 }}
               animate={{ opacity: 1, x: 0 }}
               transition={{ delay: 0.5, duration: 0.8 }}
               className="max-w-4xl"
             >
                <div className="flex items-center space-x-4 mb-6">
                   <div className="bg-purple-600 text-white px-3 py-1 rounded text-xs font-black uppercase tracking-widest italic">Featured Content</div>
                   <div className="flex items-center text-yellow-500 space-x-1 font-bold">
                      <Star size={16} fill="currentColor" />
                      <span>{featured.rating?.toFixed(1) || '8.5'}</span>
                   </div>
                </div>

                <h1 className="text-6xl md:text-9xl font-black mb-6 uppercase leading-none tracking-tighter italic">
                  {featured.title}
                </h1>

                <p className="text-lg md:text-2xl text-gray-300 mb-10 line-clamp-3 font-medium max-w-2xl leading-relaxed">
                  {featured.description}
                </p>

                <div className="flex flex-wrap gap-4">
                  <button
                    onClick={() => navigate(`/watch/${featured._id || featured.id}`)}
                    className="flex items-center space-x-3 bg-white text-black px-10 py-4 rounded-xl hover:bg-purple-600 hover:text-white transition-all duration-500 font-black uppercase tracking-widest shadow-2xl hover:scale-105 active:scale-95"
                  >
                    <Play fill="currentColor" size={24} />
                    <span>Watch Now</span>
                  </button>
                  <button
                    onClick={() => navigate(`/movie/${featured._id || featured.id}`)}
                    className="flex items-center space-x-3 bg-white/10 text-white px-10 py-4 rounded-xl hover:bg-white/20 transition-all duration-500 font-black uppercase tracking-widest backdrop-blur-xl border border-white/10"
                  >
                    <Info size={24} />
                    <span>Details</span>
                  </button>
                </div>
             </motion.div>
          </div>
        </section>
      )}

      {/* Content Rows */}
      <div className="relative z-20 -mt-32 pb-20 space-y-20 px-6 md:px-20">
        {sections.map((section, idx) => (
          <MovieRow key={idx} title={section.title} movies={section.movies} index={idx} />
        ))}
      </div>
    </div>
  );
};

const MovieRow = ({ title, movies, index }) => {
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
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay: index * 0.1, duration: 0.5 }}
      className="group relative"
    >
      <div className="flex items-end justify-between mb-8">
        <h2 className="text-3xl md:text-5xl font-black italic uppercase tracking-tighter text-white/90 group-hover:text-purple-500 transition-colors">
          {title}
        </h2>
        <div className="flex space-x-2">
           <button onClick={() => slide('left')} className="p-2 bg-white/5 rounded-full hover:bg-purple-600 transition-colors">
              <ChevronLeft size={20} />
           </button>
           <button onClick={() => slide('right')} className="p-2 bg-white/5 rounded-full hover:bg-purple-600 transition-colors">
              <ChevronRight size={20} />
           </button>
        </div>
      </div>

      <div
        ref={rowRef}
        className="flex space-x-6 overflow-x-scroll scrollbar-hide pr-20"
        style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
      >
        {movies.map((movie) => (
          <motion.div
            key={movie._id || movie.id}
            whileHover={{ scale: 1.05, y: -10 }}
            onClick={() => navigate(`/movie/${movie._id || movie.id}`)}
            className="flex-none w-48 md:w-80 relative rounded-2xl overflow-hidden cursor-pointer group/item shadow-2xl border-2 border-transparent hover:border-purple-600 transition-all duration-300"
          >
            <div className="aspect-[2/3] md:aspect-video relative overflow-hidden">
               <img
                src={movie.posterUrl}
                className="w-full h-full object-cover transition-transform duration-700 group-hover/item:scale-110"
                alt={movie.title}
                loading="lazy"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0a0a0a] via-transparent to-transparent opacity-60"></div>
            </div>

            <div className="absolute inset-0 bg-black/80 opacity-0 group-hover/item:opacity-100 transition-all duration-500 flex flex-col justify-end p-6 backdrop-blur-sm">
                <div className="bg-purple-600 w-fit px-2 py-0.5 rounded text-[8px] font-black uppercase mb-2">Premiere</div>
                <h3 className="font-black text-lg md:text-xl mb-2 italic uppercase tracking-tight leading-tight line-clamp-2">{movie.title}</h3>

                <div className="flex items-center space-x-3 text-xs text-gray-400 font-bold mb-4">
                  <span className="text-green-500 italic">HD Quality</span>
                  <span>{movie.year}</span>
                </div>

                <button className="w-full bg-white text-black py-2 rounded-lg font-black uppercase tracking-widest text-[10px] hover:bg-purple-600 hover:text-white transition-colors">
                   Watch Trailer
                </button>
            </div>
          </motion.div>
        ))}
      </div>
    </motion.div>
  );
};

export default Home;
