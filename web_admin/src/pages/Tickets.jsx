
import React, { useState, useEffect } from 'react';
import { MessageSquare, Clock, CheckCircle, AlertCircle, Search, User, Filter, ArrowRight } from 'lucide-react';
import api from '../utils/api';

const Tickets = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [reply, setReply] = useState('');

  const fetchTickets = async () => {
    try {
      const res = await api.get('/tickets');
      setTickets(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTickets();
  }, []);

  const handleReply = async (e) => {
    e.preventDefault();
    if (!reply.trim()) return;
    try {
      await api.post(`/tickets/${selectedTicket._id}/reply`, { text: reply });
      setReply('');
      fetchTickets();
      // Update local view
      const updated = await api.get('/tickets');
      setSelectedTicket(updated.data.find(t => t._id === selectedTicket._id));
    } catch (err) {
      alert('Failed to send reply');
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Open': return 'text-rose-500 bg-rose-500/10';
      case 'In Progress': return 'text-amber-500 bg-amber-500/10';
      case 'Resolved': return 'text-emerald-500 bg-emerald-500/10';
      default: return 'text-gray-500 bg-gray-500/10';
    }
  };

  return (
    <div className="flex h-full overflow-hidden bg-[#111827]">
      {/* Sidebar: Ticket List */}
      <div className="w-96 border-r border-white/5 flex flex-col h-full bg-[#1f2937]/30">
        <div className="p-6 border-b border-white/5">
          <h1 className="text-xl font-black text-white uppercase tracking-tight mb-4 flex items-center">
            <MessageSquare size={20} className="mr-2 text-[#0ea5e9]" /> Help Desk
          </h1>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={16} />
            <input
              type="text"
              placeholder="Search tickets..."
              className="w-full bg-[#111827] border border-white/10 rounded-xl pl-10 pr-4 py-2 text-sm text-white focus:outline-none focus:border-[#0ea5e9]"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto custom-scrollbar">
          {loading ? (
            <div className="p-8 text-center text-gray-500 italic">Loading tickets...</div>
          ) : tickets.map((ticket) => (
            <div
              key={ticket._id}
              onClick={() => setSelectedTicket(ticket)}
              className={`p-4 border-b border-white/5 cursor-pointer transition-all hover:bg-white/5 ${selectedTicket?._id === ticket._id ? 'bg-[#0ea5e9]/10 border-l-4 border-l-[#0ea5e9]' : ''}`}
            >
              <div className="flex justify-between items-start mb-1">
                <span className="font-bold text-white text-sm truncate pr-2">{ticket.subject}</span>
                <span className={`text-[8px] font-black uppercase px-2 py-0.5 rounded-full ${getStatusColor(ticket.status)}`}>
                  {ticket.status}
                </span>
              </div>
              <div className="flex items-center text-[10px] text-gray-500 mb-2">
                <User size={10} className="mr-1" /> {ticket.user?.name}
              </div>
              <p className="text-xs text-gray-400 line-clamp-2 leading-relaxed">{ticket.description}</p>
              <div className="mt-2 text-[9px] text-gray-600 font-bold uppercase tracking-widest flex items-center">
                <Clock size={10} className="mr-1" /> {new Date(ticket.createdAt).toLocaleDateString()}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Main Area: Ticket Detail & Conversation */}
      <div className="flex-1 flex flex-col h-full">
        {selectedTicket ? (
          <>
            <div className="p-6 border-b border-white/5 bg-[#1f2937]/50 flex justify-between items-center">
              <div>
                <h2 className="text-lg font-black text-white tracking-tight">{selectedTicket.subject}</h2>
                <div className="flex items-center space-x-3 mt-1 text-xs">
                  <span className="text-gray-400">Ticket ID: <span className="text-gray-500">{selectedTicket._id.slice(-8).toUpperCase()}</span></span>
                  <span className="text-gray-600">•</span>
                  <span className="text-gray-400 font-bold uppercase tracking-tighter">Category: {selectedTicket.category}</span>
                </div>
              </div>
              <div className="flex space-x-2">
                 <button className="px-4 py-2 bg-emerald-600/10 text-emerald-500 rounded-xl text-xs font-black hover:bg-emerald-600 hover:text-white transition-all border border-emerald-600/20">RESOLVE</button>
                 <button className="px-4 py-2 bg-rose-600/10 text-rose-500 rounded-xl text-xs font-black hover:bg-rose-600 hover:text-white transition-all border border-rose-600/20">CLOSE</button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-8 space-y-6 custom-scrollbar">
              {/* User Original Message */}
              <div className="flex items-start">
                 <div className="w-10 h-10 bg-purple-600 rounded-xl flex items-center justify-center text-white font-black mr-4 shadow-lg">{selectedTicket.user?.name?.charAt(0)}</div>
                 <div className="max-w-2xl">
                    <div className="bg-[#1f2937] p-4 rounded-2xl rounded-tl-none border border-white/5">
                        <p className="text-sm text-gray-200 leading-relaxed">{selectedTicket.description}</p>
                    </div>
                    <span className="text-[10px] text-gray-600 mt-2 block font-bold">{new Date(selectedTicket.createdAt).toLocaleString()}</span>
                 </div>
              </div>

              {/* Conversation Thread */}
              {selectedTicket.messages?.map((msg, idx) => (
                <div key={idx} className={`flex items-start ${msg.sender === selectedTicket.user?._id ? '' : 'flex-row-reverse'}`}>
                   <div className={`w-10 h-10 ${msg.sender === selectedTicket.user?._id ? 'bg-purple-600' : 'bg-[#0ea5e9]'} rounded-xl flex items-center justify-center text-white font-black ${msg.sender === selectedTicket.user?._id ? 'mr-4' : 'ml-4'} shadow-lg`}>
                      {msg.sender === selectedTicket.user?._id ? selectedTicket.user?.name?.charAt(0) : 'A'}
                   </div>
                   <div className={`max-w-2xl ${msg.sender === selectedTicket.user?._id ? '' : 'text-right'}`}>
                      <div className={`p-4 rounded-2xl border border-white/5 ${msg.sender === selectedTicket.user?._id ? 'bg-[#1f2937] rounded-tl-none' : 'bg-[#0ea5e9]/10 rounded-tr-none'}`}>
                          <p className="text-sm text-gray-200 leading-relaxed">{msg.text}</p>
                      </div>
                      <span className="text-[10px] text-gray-600 mt-2 block font-bold">{new Date(msg.createdAt).toLocaleString()}</span>
                   </div>
                </div>
              ))}
            </div>

            <div className="p-6 bg-[#1f2937]/30 border-t border-white/5">
               <form onSubmit={handleReply} className="relative">
                  <textarea
                    value={reply}
                    onChange={(e) => setReply(e.target.value)}
                    placeholder="Type your reply here..."
                    className="w-full bg-[#111827] border border-white/10 rounded-2xl p-4 pr-16 text-sm text-white focus:outline-none focus:border-[#0ea5e9] transition-all resize-none min-h-[100px]"
                  ></textarea>
                  <button
                    type="submit"
                    className="absolute bottom-4 right-4 p-3 bg-[#0ea5e9] text-white rounded-xl shadow-lg shadow-[#0ea5e9]/20 hover:bg-[#0284c7] transition-all transform active:scale-95"
                  >
                    <ArrowRight size={20} />
                  </button>
               </form>
               <div className="flex space-x-4 mt-3">
                  <button className="text-[10px] font-black text-gray-500 uppercase tracking-widest hover:text-[#0ea5e9]">Attach Files</button>
                  <button className="text-[10px] font-black text-gray-500 uppercase tracking-widest hover:text-[#0ea5e9]">Quick Reply Templates</button>
               </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center space-y-4 opacity-30">
            <MessageSquare size={100} className="text-gray-700" />
            <h3 className="text-xl font-black text-white uppercase tracking-tight">Select a ticket to view</h3>
            <p className="text-sm text-gray-500">Your customer support dashboard is ready.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Tickets;
