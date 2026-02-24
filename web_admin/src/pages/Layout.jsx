import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Plus, Trash2, Edit2, Save, X, ArrowUp, ArrowDown } from 'lucide-react';

const Layout = () => {
  const [categories, setCategories] = useState([]);
  const [sections, setSections] = useState([]);
  const [loading, setLoading] = useState(true);

  // Form states
  const [newCat, setNewCat] = useState('');
  const [newSection, setNewSection] = useState({ title: '', type: 'trending', genre: '' });
  const [editingId, setEditingId] = useState(null);
  const [editValue, setEditValue] = useState({});

  const fetchData = async () => {
    setLoading(true);
    try {
      const [catRes, secRes] = await Promise.all([
        api.get('/config/categories'),
        api.get('/config/home-sections')
      ]);
      setCategories(catRes.data);
      setSections(secRes.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // --- Categories Actions ---

  const addCategory = async () => {
    if (!newCat) return;
    try {
      await api.post('/config/categories', { name: newCat, order: categories.length + 1 });
      setNewCat('');
      fetchData();
    } catch (err) { alert('Failed to add category'); }
  };

  const deleteCategory = async (id) => {
    if (!window.confirm('Delete this filter?')) return;
    try {
      await api.delete(`/config/categories/${id}`);
      fetchData();
    } catch (err) { alert('Delete failed'); }
  };

  // --- Sections Actions ---

  const addSection = async () => {
    if (!newSection.title) return;
    try {
      await api.post('/config/home-sections', { ...newSection, order: sections.length + 1 });
      setNewSection({ title: '', type: 'trending', genre: '' });
      fetchData();
    } catch (err) { alert('Failed to add section'); }
  };

  const deleteSection = async (id) => {
    if (!window.confirm('Delete this section?')) return;
    try {
      await api.delete(`/config/home-sections/${id}`);
      fetchData();
    } catch (err) { alert('Delete failed'); }
  };

  const startEdit = (item, isSection = false) => {
    setEditingId(item._id);
    setEditValue(item);
  };

  const saveEdit = async (isSection = false) => {
    try {
      const endpoint = isSection ? `/config/home-sections/${editingId}` : `/config/categories/${editingId}`;
      await api.put(endpoint, editValue);
      setEditingId(null);
      fetchData();
    } catch (err) { alert('Update failed'); }
  };

  const moveItem = async (index, direction, isSection = false) => {
    const list = isSection ? [...sections] : [...categories];
    const newIndex = direction === 'up' ? index - 1 : index + 1;
    if (newIndex < 0 || newIndex >= list.length) return;

    // Swap locally
    const temp = list[index];
    list[index] = list[newIndex];
    list[newIndex] = temp;

    // Update orders
    const updatedItems = list.map((item, i) => ({ id: item._id, order: i + 1 }));

    try {
      const endpoint = isSection ? '/config/home-sections/reorder' : '/config/categories/reorder';
      await api.post(endpoint, { items: updatedItems });
      fetchData();
    } catch (err) { alert('Reorder failed'); }
  };

  return (
    <div className="space-y-12 pb-20">
      <div>
        <h1 className="text-3xl font-bold">Home Layout</h1>
        <p className="text-gray-400">Manage header filters and home screen sections.</p>
      </div>

      {/* Header Filters Management */}
      <section className="bg-[#1C1C1C] rounded-xl border border-white/5 p-6">
        <h2 className="text-xl font-bold mb-6 flex items-center">
           <span className="w-2 h-6 bg-purple-600 rounded mr-3"></span>
           Header Filters (Categories)
        </h2>

        <div className="flex gap-2 mb-8">
          <input
            className="flex-1 bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
            placeholder="Category Name (e.g. Anime)"
            value={newCat}
            onChange={(e) => setNewCat(e.target.value)}
          />
          <button onClick={addCategory} className="bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded font-bold flex items-center">
            <Plus size={18} className="mr-2" /> ADD
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {categories.map((cat) => (
            <div key={cat._id} className="bg-[#262626] p-4 rounded-lg flex items-center justify-between group border border-transparent hover:border-purple-500/30 transition-all">
              {editingId === cat._id ? (
                <input
                  className="bg-black/20 border border-white/20 rounded px-2 py-1 w-full mr-2"
                  value={editValue.name}
                  onChange={(e) => setEditValue({...editValue, name: e.target.value})}
                  autoFocus
                />
              ) : (
                <span className="font-medium">{cat.name}</span>
              )}

              <div className="flex gap-1">
                {editingId === cat._id ? (
                  <>
                    <button onClick={() => saveEdit(false)} className="p-2 text-green-500 hover:bg-green-500/10 rounded"><Save size={16} /></button>
                    <button onClick={() => setEditingId(null)} className="p-2 text-gray-500 hover:bg-white/10 rounded"><X size={16} /></button>
                  </>
                ) : (
                  <>
                    <button onClick={() => moveItem(categories.indexOf(cat), 'up', false)} className="p-1 text-gray-500 hover:text-white"><ArrowUp size={14}/></button>
                    <button onClick={() => moveItem(categories.indexOf(cat), 'down', false)} className="p-1 text-gray-500 hover:text-white"><ArrowDown size={14}/></button>
                    <button onClick={() => startEdit(cat)} className="p-2 text-gray-400 hover:text-white rounded opacity-0 group-hover:opacity-100 transition-opacity"><Edit2 size={16} /></button>
                    <button onClick={() => deleteCategory(cat._id)} className="p-2 text-red-500/50 hover:text-red-500 rounded opacity-0 group-hover:opacity-100 transition-opacity"><Trash2 size={16} /></button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Home Sections Management */}
      <section className="bg-[#1C1C1C] rounded-xl border border-white/5 p-6">
        <h2 className="text-xl font-bold mb-6 flex items-center">
           <span className="w-2 h-6 bg-blue-600 rounded mr-3"></span>
           Home Screen Rows
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-2 mb-8">
          <input
            className="md:col-span-2 bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
            placeholder="Section Title (e.g. Action Movies)"
            value={newSection.title}
            onChange={(e) => setNewSection({...newSection, title: e.target.value})}
          />
          <select
             className="bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none"
             value={newSection.type}
             onChange={(e) => setNewSection({...newSection, type: e.target.value})}
          >
            <option value="trending">Trending Now</option>
            <option value="top_rated">Top Rated</option>
            <option value="new_releases">New Releases</option>
            <option value="continue_watching">Continue Watching</option>
            <option value="genre">Specific Genre</option>
          </select>
          <button onClick={addSection} className="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded font-bold flex items-center justify-center">
            <Plus size={18} className="mr-2" /> ADD ROW
          </button>
          {newSection.type === 'genre' && (
            <input
              className="md:col-span-4 bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none mt-2"
              placeholder="Enter exact genre name (e.g. Action)"
              value={newSection.genre}
              onChange={(e) => setNewSection({...newSection, genre: e.target.value})}
            />
          )}
        </div>

        <div className="space-y-4">
          {sections.map((sec) => (
            <div key={sec._id} className="bg-[#262626] p-4 rounded-lg flex items-center justify-between group border border-transparent hover:border-blue-500/30 transition-all">
              <div className="flex-1">
                {editingId === sec._id ? (
                  <div className="flex gap-2">
                    <input
                      className="bg-black/20 border border-white/20 rounded px-2 py-1 flex-1"
                      value={editValue.title}
                      onChange={(e) => setEditValue({...editValue, title: e.target.value})}
                    />
                    <select
                      className="bg-black/20 border border-white/20 rounded px-2 py-1"
                      value={editValue.type}
                      onChange={(e) => setEditValue({...editValue, type: e.target.value})}
                    >
                      <option value="trending">Trending</option>
                      <option value="top_rated">Top Rated</option>
                      <option value="new_releases">New Releases</option>
                      <option value="continue_watching">Continue Watching</option>
                      <option value="genre">Genre</option>
                    </select>
                  </div>
                ) : (
                  <div>
                    <span className="font-bold text-lg">{sec.title}</span>
                    <span className="ml-4 text-xs text-blue-400 font-mono uppercase px-2 py-1 bg-blue-500/10 rounded">
                      {sec.type === 'genre' ? `Genre: ${sec.genre}` : sec.type}
                    </span>
                  </div>
                )}
              </div>

              <div className="flex gap-1 ml-4">
                {editingId === sec._id ? (
                  <>
                    <button onClick={() => saveEdit(true)} className="p-2 text-green-500 hover:bg-green-500/10 rounded"><Save size={20} /></button>
                    <button onClick={() => setEditingId(null)} className="p-2 text-gray-500 hover:bg-white/10 rounded"><X size={20} /></button>
                  </>
                ) : (
                  <>
                    <button onClick={() => moveItem(sections.indexOf(sec), 'up', true)} className="p-1 text-gray-500 hover:text-white"><ArrowUp size={18}/></button>
                    <button onClick={() => moveItem(sections.indexOf(sec), 'down', true)} className="p-1 text-gray-500 hover:text-white"><ArrowDown size={18}/></button>
                    <button onClick={() => startEdit(sec, true)} className="p-2 text-gray-400 hover:text-white rounded opacity-0 group-hover:opacity-100 transition-opacity"><Edit2 size={20} /></button>
                    <button onClick={() => deleteSection(sec._id)} className="p-2 text-red-500/50 hover:text-red-500 rounded opacity-0 group-hover:opacity-100 transition-opacity"><Trash2 size={20} /></button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

export default Layout;
