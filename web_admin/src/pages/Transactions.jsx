
import React, { useState, useEffect } from 'react';
import { DollarSign, Filter, Search, Download, ArrowUpRight, ArrowDownLeft, RefreshCcw, MoreVertical, CheckCircle, XCircle } from 'lucide-react';
import api from '../utils/api';

const Transactions = () => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  const fetchTransactions = async () => {
    try {
      const res = await api.get('/transactions');
      setTransactions(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, []);

  const getStatusColor = (status) => {
    switch (status) {
      case 'Completed': return 'text-emerald-500 bg-emerald-500/10';
      case 'Refunded': return 'text-amber-500 bg-amber-500/10';
      case 'Failed': return 'text-rose-500 bg-rose-500/10';
      default: return 'text-gray-500 bg-gray-500/10';
    }
  };

  const handleRefund = async (id) => {
    if (!window.confirm('Are you sure you want to refund this transaction?')) return;
    try {
      await api.post(`/transactions/refund/${id}`, { reason: 'Customer requested' });
      fetchTransactions();
    } catch (err) {
      alert('Refund failed');
    }
  };

  const filtered = transactions.filter(t =>
    t.user?.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    t.referenceId?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="p-8 pb-24">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-black text-white uppercase tracking-tight flex items-center">
            <DollarSign size={32} className="mr-3 text-[#0ea5e9]" /> Billing & Revenue
          </h1>
          <p className="text-gray-400 mt-1 font-medium">Monitor all incoming payments and process refund requests.</p>
        </div>
        <div className="flex gap-2">
            <button className="bg-white/5 border border-white/10 text-white px-6 py-3 rounded-2xl font-black flex items-center hover:bg-white/10 transition-all">
                <Download size={18} className="mr-2" /> EXPORT REPORT
            </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-[#1f2937] p-6 rounded-3xl border border-white/5 shadow-xl">
             <p className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Gross Revenue (30D)</p>
             <h2 className="text-3xl font-black text-white">$42,500.00</h2>
             <div className="flex items-center mt-2 text-emerald-500 text-xs font-bold">
                <ArrowUpRight size={14} className="mr-1" /> +18.4% since last month
             </div>
          </div>
          <div className="bg-[#1f2937] p-6 rounded-3xl border border-white/5 shadow-xl">
             <p className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Average Order Value</p>
             <h2 className="text-3xl font-black text-white">$14.20</h2>
             <div className="flex items-center mt-2 text-[#0ea5e9] text-xs font-bold">
                <RefreshCcw size={14} className="mr-1" /> Based on 2,993 orders
             </div>
          </div>
          <div className="bg-[#1f2937] p-6 rounded-3xl border border-white/5 shadow-xl">
             <p className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Refund Rate</p>
             <h2 className="text-3xl font-black text-white">0.82%</h2>
             <div className="flex items-center mt-2 text-emerald-500 text-xs font-bold">
                <CheckCircle size={14} className="mr-1" /> Below industry benchmark
             </div>
          </div>
      </div>

      <div className="bg-[#1f2937] p-4 rounded-2xl border border-white/5 mb-8 flex flex-col md:flex-row gap-4 items-center">
        <div className="relative flex-1 w-full">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
          <input
            type="text"
            placeholder="Search by customer name or transaction ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-sm text-white focus:outline-none focus:border-[#0ea5e9]"
          />
        </div>
        <button className="flex items-center space-x-2 bg-[#111827] border border-white/10 px-6 py-3 rounded-xl text-gray-400 hover:text-white transition-colors">
          <Filter size={18} />
          <span className="text-sm font-bold uppercase">Filter Status</span>
        </button>
      </div>

      <div className="bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden shadow-2xl">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-[#111827] text-gray-500 text-[10px] font-black uppercase tracking-widest border-b border-white/5">
              <th className="px-6 py-5">Customer</th>
              <th className="px-6 py-5">Amount</th>
              <th className="px-6 py-5">Type</th>
              <th className="px-6 py-5">Status</th>
              <th className="px-6 py-5">Reference ID</th>
              <th className="px-6 py-5">Date</th>
              <th className="px-6 py-5 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {loading ? (
              <tr>
                <td colSpan="7" className="px-6 py-10 text-center text-gray-500 italic">Accessing billing records...</td>
              </tr>
            ) : filtered.map((tx) => (
              <tr key={tx._id} className="hover:bg-white/[0.01] transition-colors">
                <td className="px-6 py-5">
                   <div>
                      <div className="font-bold text-white text-sm">{tx.user?.name}</div>
                      <div className="text-[10px] text-gray-500 uppercase font-black">{tx.user?.email}</div>
                   </div>
                </td>
                <td className="px-6 py-5">
                   <span className="text-white font-black text-sm">${tx.amount.toFixed(2)} <span className="text-gray-500 text-[10px] ml-1">{tx.currency}</span></span>
                </td>
                <td className="px-6 py-5 text-gray-300 text-xs font-bold uppercase tracking-widest">{tx.type}</td>
                <td className="px-6 py-5">
                   <span className={`px-2 py-1 rounded text-[9px] font-black uppercase tracking-tighter ${getStatusColor(tx.status)}`}>
                     {tx.status}
                   </span>
                </td>
                <td className="px-6 py-5 text-gray-500 font-mono text-[10px] uppercase">{tx.referenceId || tx._id.slice(-12)}</td>
                <td className="px-6 py-5 text-gray-400 text-xs font-medium">{new Date(tx.createdAt).toLocaleDateString()}</td>
                <td className="px-6 py-5 text-right">
                   {tx.status === 'Completed' && (
                     <button
                       onClick={() => handleRefund(tx._id)}
                       className="text-[10px] font-black text-rose-500 hover:text-rose-400 uppercase tracking-tighter"
                     >
                       ISSUE REFUND
                     </button>
                   )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Transactions;
