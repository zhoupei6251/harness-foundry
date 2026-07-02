#!/usr/bin/env python3
"""
Harness Foundry Dashboard - 可视化浏览组件
TkInter GUI for managing Harness Foundry skills, agents, and statistics.
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import os
import json
import re
from pathlib import Path
from typing import Dict, List, Optional
import logging
import webbrowser

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# DATA LOADERS - Load Harness Foundry data from the project
# ============================================================================

def get_project_path() -> str:
    """Get the Harness Foundry project path."""
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_skills(project_path: str) -> List[Dict]:
    """Load skills from skills directory."""
    skills_dir = os.path.join(project_path, "skills")
    skills = []

    if os.path.exists(skills_dir):
        for item in sorted(os.listdir(skills_dir)):
            skill_path = os.path.join(skills_dir, item)
            if os.path.isdir(skill_path):
                skill_file = os.path.join(skill_path, "SKILL.md")
                description = item.replace('-', ' ').replace('_', ' ').title()
                category = "General"
                status = "active"
                layer = "optional"

                if os.path.exists(skill_file):
                    try:
                        with open(skill_file, 'r', encoding='utf-8') as f:
                            content = f.read()
                            # Extract description from first lines
                            lines = content.split('\n')
                            for line in lines:
                                if line.startswith('---'):
                                    continue
                                if line.strip() and not line.startswith('#'):
                                    description = line.strip()[:100]
                                    break
                                if line.startswith('# '):
                                    description = line[2:].strip()[:100]
                                    break
                    except Exception as e:
                        logger.debug("Failed to parse skill file %s: %s", skill_file, e)

                # Determine category from path
                item_lower = item.lower()
                if any(kw in item_lower for kw in ['python', 'django', 'fastapi']):
                    category = "Python"
                elif any(kw in item_lower for kw in ['golang', 'go-']):
                    category = "Go"
                elif any(kw in item_lower for kw in ['frontend', 'react', 'vue', 'css', 'ui']):
                    category = "Frontend"
                elif any(kw in item_lower for kw in ['backend', 'api', 'server']):
                    category = "Backend"
                elif any(kw in item_lower for kw in ['security', 'auth']):
                    category = "Security"
                elif any(kw in item_lower for kw in ['testing', 'tdd', 'test']):
                    category = "Testing"
                elif any(kw in item_lower for kw in ['docker', 'deployment', 'devops', 'ci']):
                    category = "DevOps"
                elif any(kw in item_lower for kw in ['novel', 'writing', 'writer']):
                    category = "Novel"
                elif any(kw in item_lower for kw in ['news', 'journalism']):
                    category = "News"
                elif any(kw in item_lower for kw in ['memory', 'context', 'prompt']):
                    category = "Memory"
                elif any(kw in item_lower for kw in ['agent', 'orchestrat', 'dispatch']):
                    category = "Agent"

                # Check layer
                meta_file = os.path.join(skill_path, "_meta.json")
                if os.path.exists(meta_file):
                    try:
                        with open(meta_file, 'r', encoding='utf-8') as f:
                            meta = json.load(f)
                            if 'layer' in meta:
                                layer = meta['layer']
                    except Exception:
                        pass

                skills.append({
                    'name': item,
                    'description': description,
                    'category': category,
                    'status': status,
                    'layer': layer,
                    'path': skill_path
                })

    return skills


def load_agents(project_path: str) -> List[Dict]:
    """Load agents by scanning the agents/ directory."""
    agents_dir = os.path.join(project_path, "agents")
    agents = []

    if os.path.isdir(agents_dir):
        for item in sorted(os.listdir(agents_dir)):
            if not item.endswith('.md'):
                continue
            agent_path = os.path.join(agents_dir, item)
            name = os.path.splitext(item)[0]
            description = ''
            domain = 'shared'
            tools = []

            try:
                with open(agent_path, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Parse YAML frontmatter
                if content.startswith('---'):
                    end = content.find('\n---', 3)
                    if end != -1:
                        for fm_line in content[3:end].splitlines():
                            stripped = fm_line.strip()
                            if stripped.startswith('name:'):
                                name = stripped.split(':', 1)[1].strip().strip('"\'')
                            elif stripped.startswith('description:'):
                                description = stripped.split(':', 1)[1].strip().strip('"\'')
                            elif stripped.startswith('domain:'):
                                domain = stripped.split(':', 1)[1].strip().strip('"\'')
                            elif stripped.startswith('tools:'):
                                tools_str = stripped.split(':', 1)[1].strip()
                                # Parse tools array from YAML
                                if '[' in tools_str:
                                    tools = [t.strip().strip('"\',') for t in tools_str[1:-1].split(',')]
                else:
                    # Try to extract from first heading
                    for line in content.split('\n')[:10]:
                        if line.startswith('# '):
                            description = line[2:].strip()
                            break

            except OSError:
                content = ''

            # Determine domain from name
            name_lower = name.lower()
            if name_lower.startswith(('coder', 'debugger', 'reviewer', 'test', 'explorer', 'implement')):
                domain = 'code'
            elif name_lower.startswith(('leader', 'writer', 'planner', 'novel', 'humanizer', 'editor', 'memory')):
                domain = 'novel'
            elif name_lower.startswith(('news', 'fact')):
                domain = 'news'

            agents.append({
                'name': name,
                'description': description or name.replace('-', ' ').title(),
                'domain': domain,
                'tools': tools,
                'path': agent_path
            })

    return agents


def load_hooks(project_path: str) -> List[Dict]:
    """Load hooks from hooks directory."""
    hooks_dir = os.path.join(project_path, "hooks")
    hooks = []

    if os.path.exists(hooks_dir):
        hooks_file = os.path.join(hooks_dir, "hooks.json")
        if os.path.exists(hooks_file):
            try:
                with open(hooks_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if 'hooks' in data:
                        for hook in data['hooks']:
                            hooks.append({
                                'name': hook.get('name', 'unknown'),
                                'type': hook.get('type', 'unknown'),
                                'description': hook.get('description', ''),
                                'enabled': hook.get('enabled', True)
                            })
            except Exception as e:
                logger.debug("Failed to parse hooks.json: %s", e)

    return hooks


def load_statistics(project_path: str) -> Dict:
    """Load statistics from the project."""
    stats = {
        'total_skills': 0,
        'total_agents': 0,
        'total_hooks': 0,
        'skills_by_category': {},
        'skills_by_layer': {},
        'agents_by_domain': {},
        'categories': [],
        'layers': ['must-core', 'optional'],
        'domains': ['code', 'novel', 'news', 'shared']
    }

    skills = load_skills(project_path)
    agents = load_agents(project_path)
    hooks = load_hooks(project_path)

    stats['total_skills'] = len(skills)
    stats['total_agents'] = len(agents)
    stats['total_hooks'] = len(hooks)

    # Skills by category
    for skill in skills:
        cat = skill['category']
        stats['skills_by_category'][cat] = stats['skills_by_category'].get(cat, 0) + 1

        layer = skill['layer']
        if layer not in stats['skills_by_layer']:
            stats['skills_by_layer'][layer] = 0
        stats['skills_by_layer'][layer] += 1

    stats['categories'] = sorted(stats['skills_by_category'].keys())

    # Agents by domain
    for agent in agents:
        domain = agent['domain']
        stats['agents_by_domain'][domain] = stats['agents_by_domain'].get(domain, 0) + 1

    return stats


# ============================================================================
# MAIN APPLICATION
# ============================================================================

class HarnessDashboard(tk.Tk):
    """Main Harness Foundry Dashboard Application"""

    def __init__(self):
        super().__init__()

        self.project_path = get_project_path()
        self.title("Harness Foundry Dashboard")
        self.geometry("1200x800")
        self.minsize(900, 600)

        # Load data
        self.skills = load_skills(self.project_path)
        self.agents = load_agents(self.project_path)
        self.hooks = load_hooks(self.project_path)
        self.statistics = load_statistics(self.project_path)

        # Settings
        self.settings = {
            'theme': 'light',
            'font_family': 'Arial',
            'font_size': 10
        }

        # Setup UI
        self.setup_styles()
        self.create_widgets()

        # Center window
        self.center_window()

    def setup_styles(self):
        """Setup ttk styles for modern look."""
        style = ttk.Style()
        style.theme_use('clam')

        # Colors
        bg_light = '#f5f5f5'
        fg_light = '#333333'

        # Configure styles
        style.configure('.', background=bg_light)
        style.configure('Title.TLabel', font=('Arial', 18, 'bold'), foreground='#2c5aa0')
        style.configure('Header.TLabel', font=('Arial', 12, 'bold'))
        style.configure('Stat.TLabel', font=('Arial', 28, 'bold'), foreground='#2c5aa0')
        style.configure('Card.TFrame', background='#ffffff', relief='solid', borderwidth=1)

        # Configure Treeview
        style.configure('Treeview', font=('Arial', 10), rowheight=25)
        style.configure('Treeview.Heading', font=('Arial', 10, 'bold'))

        # Configure Notebook
        style.configure('TNotebook', background=bg_light)
        style.configure('TNotebook.Tab', padding=[15, 5], font=('Arial', 11))

    def center_window(self):
        """Center the window on screen."""
        self.update_idletasks()
        width = self.winfo_width()
        height = self.winfo_height()
        x = (self.winfo_screenwidth() // 2) - (width // 2)
        y = (self.winfo_screenheight() // 2) - (height // 2)
        self.geometry(f'{width}x{height}+{x}+{y}')

    def create_widgets(self):
        """Create all UI widgets."""
        # Main container
        main_frame = ttk.Frame(self)
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Header
        self.create_header(main_frame)

        # Notebook (tabs)
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 10))

        # Create tabs
        self.create_overview_tab()
        self.create_skills_tab()
        self.create_agents_tab()
        self.create_statistics_tab()
        self.create_settings_tab()

        # Status bar
        self.create_status_bar(main_frame)

    def create_header(self, parent):
        """Create header with title and quick stats."""
        header_frame = ttk.Frame(parent)
        header_frame.pack(fill=tk.X, padx=10, pady=10)

        # Title
        title_label = ttk.Label(header_frame, text="Harness Foundry", style='Title.TLabel')
        title_label.pack(side=tk.LEFT)

        # Quick stats
        stats_frame = ttk.Frame(header_frame)
        stats_frame.pack(side=tk.RIGHT)

        quick_stats = [
            (len(self.skills), "Skills"),
            (len(self.agents), "Agents"),
            (len(self.hooks), "Hooks")
        ]

        for i, (count, label) in enumerate(quick_stats):
            stat_frame = ttk.Frame(stats_frame)
            stat_frame.pack(side=tk.LEFT, padx=15)

            ttk.Label(stat_frame, text=str(count), style='Stat.TLabel').pack()
            ttk.Label(stat_frame, text=label, font=('Arial', 9), foreground='gray').pack()

    def create_status_bar(self, parent):
        """Create status bar."""
        status_frame = ttk.Frame(parent)
        status_frame.pack(fill=tk.X, padx=10, pady=(0, 5))

        self.status_label = ttk.Label(
            status_frame,
            text=f"Ready | Project: {self.project_path}",
            font=('Arial', 9),
            foreground='gray'
        )
        self.status_label.pack(side=tk.LEFT)

    # =========================================================================
    # OVERVIEW TAB
    # =========================================================================

    def create_overview_tab(self):
        """Create Overview tab with quick summary."""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="Overview")

        # Title
        ttk.Label(frame, text="Harness Foundry Overview", style='Header.TLabel').pack(
            anchor=tk.W, padx=20, pady=15
        )

        # Cards container
        cards_frame = ttk.Frame(frame)
        cards_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

        # Skills overview
        self.create_overview_card(cards_frame, 0, 0, "Skills", len(self.skills),
                                   [(cat, count) for cat, count in
                                    sorted(self.statistics['skills_by_category'].items(),
                                           key=lambda x: -x[1])[:5]],
                                   "#4CAF50")

        # Agents overview
        self.create_overview_card(cards_frame, 0, 1, "Agents", len(self.agents),
                                   [(domain, count) for domain, count in
                                    sorted(self.statistics['agents_by_domain'].items(),
                                           key=lambda x: -x[1])],
                                   "#2196F3")

        # Layers overview
        self.create_overview_card(cards_frame, 1, 0, "Skill Layers", "100%",
                                   [(layer, count) for layer, count in
                                    self.statistics['skills_by_layer'].items()],
                                   "#FF9800")

        # Architecture info
        info_frame = ttk.LabelFrame(cards_frame, text="Architecture", padding=15)
        info_frame.grid(row=1, column=1, padx=10, pady=10, sticky='nsew')

        arch_info = """
Domains: code / novel / news

Roles: planner, coder, reviewer, debugger,
       writer, editor, leader, ...

Features:
- Parallel dispatch (<=5 workers)
- Two-stage review
- Design gate enforcement
- Memory management
        """
        ttk.Label(info_frame, text=arch_info.strip(), justify=tk.LEFT).pack(anchor=tk.W)

        # Configure grid
        cards_frame.columnconfigure(0, weight=1)
        cards_frame.columnconfigure(1, weight=1)
        cards_frame.rowconfigure(0, weight=1)
        cards_frame.rowconfigure(1, weight=1)

    def create_overview_card(self, parent, row, col, title, total, items, color):
        """Create an overview card widget."""
        card = ttk.LabelFrame(parent, text=title, padding=15)
        card.grid(row=row, column=col, padx=10, pady=10, sticky='nsew')

        # Total count
        total_label = ttk.Label(card, text=str(total), font=('Arial', 32, 'bold'), foreground=color)
        total_label.pack(pady=(0, 10))

        # Items
        for item_name, count in items:
            item_frame = ttk.Frame(card)
            item_frame.pack(fill=tk.X, pady=2)

            ttk.Label(item_frame, text=item_name, font=('Arial', 9)).pack(side=tk.LEFT)
            ttk.Label(item_frame, text=str(count), font=('Arial', 9, 'bold')).pack(side=tk.RIGHT)

    # =========================================================================
    # SKILLS TAB
    # =========================================================================

    def create_skills_tab(self):
        """Create Skills tab."""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text=f"Skills ({len(self.skills)})")

        # Search and filter
        filter_frame = ttk.Frame(frame)
        filter_frame.pack(fill=tk.X, padx=10, pady=10)

        ttk.Label(filter_frame, text="Search:").pack(side=tk.LEFT)
        self.skill_search = ttk.Entry(filter_frame, width=25)
        self.skill_search.pack(side=tk.LEFT, padx=5)
        self.skill_search.bind('<KeyRelease>', self.filter_skills)

        ttk.Label(filter_frame, text="Category:").pack(side=tk.LEFT, padx=(20, 0))
        self.skill_category = ttk.Combobox(
            filter_frame,
            values=['All'] + self.statistics['categories'],
            width=15,
            state='readonly'
        )
        self.skill_category.set('All')
        self.skill_category.pack(side=tk.LEFT, padx=5)
        self.skill_category.bind('<<ComboboxSelected>>', self.filter_skills)

        ttk.Label(filter_frame, text="Layer:").pack(side=tk.LEFT, padx=(20, 0))
        self.skill_layer = ttk.Combobox(
            filter_frame,
            values=['All'] + self.statistics['layers'],
            width=12,
            state='readonly'
        )
        self.skill_layer.set('All')
        self.skill_layer.pack(side=tk.LEFT, padx=5)
        self.skill_layer.bind('<<ComboboxSelected>>', self.filter_skills)

        ttk.Label(filter_frame, text="Count:").pack(side=tk.LEFT, padx=(20, 0))
        self.skill_count_label = ttk.Label(filter_frame, text=str(len(self.skills)))
        self.skill_count_label.pack(side=tk.LEFT)

        # Split pane
        paned = ttk.PanedWindow(frame, orient=tk.HORIZONTAL)
        paned.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 10))

        # Skill list
        list_frame = ttk.Frame(paned)
        paned.add(list_frame, weight=1)

        columns = ('name', 'category', 'layer', 'description')
        self.skill_tree = ttk.Treeview(list_frame, columns=columns, show='tree headings')
        self.skill_tree.heading('#0', text='#')
        self.skill_tree.heading('name', text='Skill Name')
        self.skill_tree.heading('category', text='Category')
        self.skill_tree.heading('layer', text='Layer')
        self.skill_tree.heading('description', text='Description')

        self.skill_tree.column('#0', width=40)
        self.skill_tree.column('name', width=180)
        self.skill_tree.column('category', width=100)
        self.skill_tree.column('layer', width=80)
        self.skill_tree.column('description', width=250)

        self.skill_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.skill_tree.yview)
        self.skill_tree.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Details panel
        details_frame = ttk.Frame(paned)
        paned.add(details_frame, weight=1)

        ttk.Label(details_frame, text="Details", style='Header.TLabel').pack(anchor=tk.W, pady=(0, 5))

        self.skill_details = scrolledtext.ScrolledText(details_frame, wrap=tk.WORD, height=20)
        self.skill_details.pack(fill=tk.BOTH, expand=True)

        # Open file button
        ttk.Button(details_frame, text="Open in Editor",
                  command=self.open_skill_file).pack(pady=5)

        self.skill_tree.bind('<<TreeviewSelect>>', self.on_skill_select)

        self.populate_skills(self.skills)

    def populate_skills(self, skills: List[Dict]):
        """Populate skills list."""
        for item in self.skill_tree.get_children():
            self.skill_tree.delete(item)

        for i, skill in enumerate(skills, 1):
            self.skill_tree.insert('', tk.END, text=str(i),
                                  values=(skill['name'], skill['category'],
                                         skill['layer'], skill['description']))

    def filter_skills(self, event=None):
        """Filter skills based on search and filters."""
        search = self.skill_search.get().lower()
        category = self.skill_category.get()
        layer = self.skill_layer.get()

        filtered = self.skills

        if category != 'All':
            filtered = [s for s in filtered if s['category'] == category]

        if layer != 'All':
            filtered = [s for s in filtered if s['layer'] == layer]

        if search:
            filtered = [s for s in filtered
                       if search in s['name'].lower()
                       or search in s['description'].lower()]

        self.populate_skills(filtered)
        self.skill_count_label.config(text=str(len(filtered)))

    def on_skill_select(self, event):
        """Handle skill selection."""
        selection = self.skill_tree.selection()
        if not selection:
            return

        item = self.skill_tree.item(selection[0])
        skill_name = item['values'][0]

        skill = next((s for s in self.skills if s['name'] == skill_name), None)
        if skill:
            details = f"""Skill: {skill['name']}

Category: {skill['category']}
Layer: {skill['layer']}
Status: {skill['status']}

Description:
{skill['description']}

Path: {skill['path']}

---
Usage: This skill is automatically activated based on context."""
            self.skill_details.delete('1.0', tk.END)
            self.skill_details.insert('1.0', details)

    def open_skill_file(self):
        """Open the selected skill file in default editor."""
        selection = self.skill_tree.selection()
        if not selection:
            return

        item = self.skill_tree.item(selection[0])
        skill_name = item['values'][0]

        skill = next((s for s in self.skills if s['name'] == skill_name), None)
        if skill:
            skill_file = os.path.join(skill['path'], 'SKILL.md')
            if os.path.exists(skill_file):
                try:
                    webbrowser.open(Path(skill_file).as_uri())
                except Exception as e:
                    messagebox.showerror("Error", f"Could not open file: {e}")

    # =========================================================================
    # AGENTS TAB
    # =========================================================================

    def create_agents_tab(self):
        """Create Agents tab."""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text=f"Agents ({len(self.agents)})")

        # Search bar
        search_frame = ttk.Frame(frame)
        search_frame.pack(fill=tk.X, padx=10, pady=10)

        ttk.Label(search_frame, text="Search:").pack(side=tk.LEFT)
        self.agent_search = ttk.Entry(search_frame, width=30)
        self.agent_search.pack(side=tk.LEFT, padx=5)
        self.agent_search.bind('<KeyRelease>', self.filter_agents)

        ttk.Label(search_frame, text="Domain:").pack(side=tk.LEFT, padx=(20, 0))
        self.agent_domain = ttk.Combobox(
            search_frame,
            values=['All'] + self.statistics['domains'],
            width=12,
            state='readonly'
        )
        self.agent_domain.set('All')
        self.agent_domain.pack(side=tk.LEFT, padx=5)
        self.agent_domain.bind('<<ComboboxSelected>>', self.filter_agents)

        ttk.Label(search_frame, text="Count:").pack(side=tk.LEFT, padx=(20, 0))
        self.agent_count_label = ttk.Label(search_frame, text=str(len(self.agents)))
        self.agent_count_label.pack(side=tk.LEFT)

        # Split pane
        paned = ttk.PanedWindow(frame, orient=tk.HORIZONTAL)
        paned.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 10))

        # Agent list
        list_frame = ttk.Frame(paned)
        paned.add(list_frame, weight=2)

        columns = ('name', 'domain', 'description')
        self.agent_tree = ttk.Treeview(list_frame, columns=columns, show='tree headings')
        self.agent_tree.heading('#0', text='#')
        self.agent_tree.heading('name', text='Agent Name')
        self.agent_tree.heading('domain', text='Domain')
        self.agent_tree.heading('description', text='Description')

        self.agent_tree.column('#0', width=40)
        self.agent_tree.column('name', width=180)
        self.agent_tree.column('domain', width=80)
        self.agent_tree.column('description', width=300)

        self.agent_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.agent_tree.yview)
        self.agent_tree.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Details panel
        details_frame = ttk.Frame(paned)
        paned.add(details_frame, weight=1)

        ttk.Label(details_frame, text="Details", style='Header.TLabel').pack(anchor=tk.W, pady=(0, 5))

        self.agent_details = scrolledtext.ScrolledText(details_frame, wrap=tk.WORD, height=20)
        self.agent_details.pack(fill=tk.BOTH, expand=True)

        self.agent_tree.bind('<<TreeviewSelect>>', self.on_agent_select)

        self.populate_agents(self.agents)

    def populate_agents(self, agents: List[Dict]):
        """Populate agents list."""
        for item in self.agent_tree.get_children():
            self.agent_tree.delete(item)

        for i, agent in enumerate(agents, 1):
            self.agent_tree.insert('', tk.END, text=str(i),
                                  values=(agent['name'], agent['domain'], agent['description']))

    def filter_agents(self, event=None):
        """Filter agents based on search and domain."""
        query = self.agent_search.get().lower()
        domain = self.agent_domain.get()

        filtered = self.agents

        if domain != 'All':
            filtered = [a for a in filtered if a['domain'] == domain]

        if query:
            filtered = [a for a in filtered
                       if query in a['name'].lower()
                       or query in a['description'].lower()]

        self.populate_agents(filtered)
        self.agent_count_label.config(text=str(len(filtered)))

    def on_agent_select(self, event):
        """Handle agent selection."""
        selection = self.agent_tree.selection()
        if not selection:
            return

        item = self.agent_tree.item(selection[0])
        agent_name = item['values'][0]

        agent = next((a for a in self.agents if a['name'] == agent_name), None)
        if agent:
            tools_str = ', '.join(agent['tools']) if agent['tools'] else 'All tools'

            details = f"""Agent: {agent['name']}

Domain: {agent['domain']}
Tools: {tools_str}

Description:
{agent['description']}

Path: {agent['path']}

---
Usage: This agent is invoked via orchestration or skill routing."""
            self.agent_details.delete('1.0', tk.END)
            self.agent_details.insert('1.0', details)

    # =========================================================================
    # STATISTICS TAB
    # =========================================================================

    def create_statistics_tab(self):
        """Create Statistics tab."""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="Statistics")

        # Title
        ttk.Label(frame, text="Component Statistics", style='Header.TLabel').pack(
            anchor=tk.W, padx=20, pady=15
        )

        # Stats container
        stats_container = ttk.Frame(frame)
        stats_container.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

        # Skills breakdown
        skills_frame = ttk.LabelFrame(stats_container, text="Skills by Category", padding=15)
        skills_frame.grid(row=0, column=0, padx=10, pady=10, sticky='nsew')

        for i, (cat, count) in enumerate(sorted(self.statistics['skills_by_category'].items())):
            row_frame = ttk.Frame(skills_frame)
            row_frame.pack(fill=tk.X, pady=3)

            ttk.Label(row_frame, text=cat, width=20).pack(side=tk.LEFT)

            # Progress bar
            max_count = max(self.statistics['skills_by_category'].values()) if self.statistics['skills_by_category'] else 1
            progress = int((count / max_count) * 100)

            bar = ttk.Progressbar(row_frame, length=150, mode='determinate', value=progress)
            bar.pack(side=tk.LEFT, padx=10)

            ttk.Label(row_frame, text=str(count), width=5).pack(side=tk.LEFT)

        # Agents breakdown
        agents_frame = ttk.LabelFrame(stats_container, text="Agents by Domain", padding=15)
        agents_frame.grid(row=0, column=1, padx=10, pady=10, sticky='nsew')

        for i, (domain, count) in enumerate(sorted(self.statistics['agents_by_domain'].items())):
            row_frame = ttk.Frame(agents_frame)
            row_frame.pack(fill=tk.X, pady=3)

            ttk.Label(row_frame, text=domain.title(), width=20).pack(side=tk.LEFT)

            max_count = max(self.statistics['agents_by_domain'].values()) if self.statistics['agents_by_domain'] else 1
            progress = int((count / max_count) * 100)

            bar = ttk.Progressbar(row_frame, length=150, mode='determinate', value=progress)
            bar.pack(side=tk.LEFT, padx=10)

            ttk.Label(row_frame, text=str(count), width=5).pack(side=tk.LEFT)

        # Layer breakdown
        layer_frame = ttk.LabelFrame(stats_container, text="Skill Layers", padding=15)
        layer_frame.grid(row=1, column=0, padx=10, pady=10, sticky='nsew')

        for i, (layer, count) in enumerate(self.statistics['skills_by_layer'].items()):
            row_frame = ttk.Frame(layer_frame)
            row_frame.pack(fill=tk.X, pady=3)

            ttk.Label(row_frame, text=layer, width=20).pack(side=tk.LEFT)

            max_count = sum(self.statistics['skills_by_layer'].values())
            progress = int((count / max_count) * 100)

            bar = ttk.Progressbar(row_frame, length=150, mode='determinate', value=progress)
            bar.pack(side=tk.LEFT, padx=10)

            ttk.Label(row_frame, text=str(count), width=5).pack(side=tk.LEFT)

        # Total summary
        summary_frame = ttk.LabelFrame(stats_container, text="Summary", padding=15)
        summary_frame.grid(row=1, column=1, padx=10, pady=10, sticky='nsew')

        summary_items = [
            ("Total Skills", self.statistics['total_skills']),
            ("Total Agents", self.statistics['total_agents']),
            ("Total Hooks", self.statistics['total_hooks']),
            ("Categories", len(self.statistics['categories']))
        ]

        for i, (label, value) in enumerate(summary_items):
            row_frame = ttk.Frame(summary_frame)
            row_frame.pack(fill=tk.X, pady=5)

            ttk.Label(row_frame, text=label, width=20).pack(side=tk.LEFT)
            ttk.Label(row_frame, text=str(value), font=('Arial', 10, 'bold')).pack(side=tk.RIGHT)

        # Configure grid
        stats_container.columnconfigure(0, weight=1)
        stats_container.columnconfigure(1, weight=1)

    # =========================================================================
    # SETTINGS TAB
    # =========================================================================

    def create_settings_tab(self):
        """Create Settings tab."""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="Settings")

        # Project path
        path_frame = ttk.LabelFrame(frame, text="Project Path", padding=15)
        path_frame.pack(fill=tk.X, padx=20, pady=15)

        path_row = ttk.Frame(path_frame)
        path_row.pack(fill=tk.X)

        self.path_entry = ttk.Entry(path_row, width=60)
        self.path_entry.insert(0, self.project_path)
        self.path_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)

        ttk.Button(path_row, text="Browse...", command=self.browse_path).pack(side=tk.LEFT, padx=5)

        # Appearance
        appearance_frame = ttk.LabelFrame(frame, text="Appearance", padding=15)
        appearance_frame.pack(fill=tk.X, padx=20, pady=15)

        ttk.Label(appearance_frame, text="Theme:").pack(anchor=tk.W)

        self.theme_var = tk.StringVar(value='light')
        ttk.Radiobutton(appearance_frame, text="Light", variable=self.theme_var,
                       value='light', command=self.apply_theme).pack(anchor=tk.W)
        ttk.Radiobutton(appearance_frame, text="Dark", variable=self.theme_var,
                       value='dark', command=self.apply_theme).pack(anchor=tk.W)

        # Font settings
        font_frame = ttk.LabelFrame(frame, text="Font", padding=15)
        font_frame.pack(fill=tk.X, padx=20, pady=15)

        ttk.Label(font_frame, text="Font Family:").pack(anchor=tk.W)

        self.font_var = tk.StringVar(value='Arial')
        fonts = ['Arial', 'Helvetica', 'Times New Roman', 'Courier New', 'Verdana', 'Georgia']
        self.font_combo = ttk.Combobox(font_frame, textvariable=self.font_var,
                                        values=fonts, state='readonly')
        self.font_combo.pack(anchor=tk.W, fill=tk.X, pady=(5, 10))
        self.font_combo.bind('<<ComboboxSelected>>', lambda e: self.apply_theme())

        ttk.Label(font_frame, text="Font Size:").pack(anchor=tk.W)

        self.size_var = tk.StringVar(value='10')
        sizes = ['8', '9', '10', '11', '12', '14', '16']
        self.size_combo = ttk.Combobox(font_frame, textvariable=self.size_var,
                                       values=sizes, state='readonly', width=10)
        self.size_combo.pack(anchor=tk.W, pady=(5, 0))
        self.size_combo.bind('<<ComboboxSelected>>', lambda e: self.apply_theme())

        # Quick Actions
        actions_frame = ttk.LabelFrame(frame, text="Quick Actions", padding=15)
        actions_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=15)

        ttk.Button(actions_frame, text="Open Skills Directory",
                  command=self.open_skills_dir).pack(fill=tk.X, pady=3)
        ttk.Button(actions_frame, text="Open Agents Directory",
                  command=self.open_agents_dir).pack(fill=tk.X, pady=3)
        ttk.Button(actions_frame, text="Refresh Data",
                  command=self.refresh_data).pack(fill=tk.X, pady=3)

        # About
        about_frame = ttk.LabelFrame(frame, text="About", padding=15)
        about_frame.pack(fill=tk.X, padx=20, pady=15)

        about_text = """Harness Foundry Dashboard v1.0.0

A cross-platform desktop application for
managing and exploring Harness Foundry components.

Features:
- Browse and search 194+ skills
- Explore 30+ agents across 3 domains
- View component statistics
- Dark/Light theme support

Project: github.com/zhoupei/harness-foundry"""

        ttk.Label(about_frame, text=about_text, justify=tk.LEFT).pack(anchor=tk.W)

    def browse_path(self):
        """Browse for project path."""
        from tkinter import filedialog
        path = filedialog.askdirectory(initialdir=self.project_path)
        if path:
            self.path_entry.delete(0, tk.END)
            self.path_entry.insert(0, path)

    def open_skills_dir(self):
        """Open skills directory."""
        skills_path = os.path.join(self.project_path, 'skills')
        try:
            webbrowser.open(Path(skills_path).as_uri())
        except Exception as e:
            messagebox.showerror("Error", f"Could not open directory: {e}")

    def open_agents_dir(self):
        """Open agents directory."""
        agents_path = os.path.join(self.project_path, 'agents')
        try:
            webbrowser.open(Path(agents_path).as_uri())
        except Exception as e:
            messagebox.showerror("Error", f"Could not open directory: {e}")

    def refresh_data(self):
        """Refresh all data."""
        self.project_path = self.path_entry.get()

        if not os.path.exists(self.project_path):
            messagebox.showerror("Error", "Project path does not exist")
            return

        self.skills = load_skills(self.project_path)
        self.agents = load_agents(self.project_path)
        self.hooks = load_hooks(self.project_path)
        self.statistics = load_statistics(self.project_path)

        # Update tabs
        self.notebook.tab(1, text=f"Skills ({len(self.skills)})")
        self.notebook.tab(2, text=f"Agents ({len(self.agents)})")

        # Repopulate lists
        self.populate_skills(self.skills)
        self.populate_agents(self.agents)

        # Update status
        self.status_label.config(
            text=f"Data refreshed | Project: {self.project_path}"
        )

        messagebox.showinfo("Success", "Data refreshed successfully!")

    def apply_theme(self):
        """Apply theme settings."""
        theme = self.theme_var.get()
        font_family = self.font_var.get()
        font_size = int(self.size_var.get())

        if theme == 'dark':
            bg_color = '#2b2b2b'
            fg_color = '#ffffff'
            entry_bg = '#3c3c3c'
            frame_bg = '#2b2b2b'
            select_bg = '#0f5a9e'
        else:
            bg_color = '#f5f5f5'
            fg_color = '#333333'
            entry_bg = '#ffffff'
            frame_bg = '#f5f5f5'
            select_bg = '#e0e0e0'

        self.configure(background=bg_color)

        style = ttk.Style()
        style.configure('.', background=bg_color, foreground=fg_color)
        style.configure('TFrame', background=bg_color)
        style.configure('TLabel', background=bg_color, foreground=fg_color)
        style.configure('TNotebook', background=bg_color)
        style.configure('TEntry', fieldbackground=entry_bg, foreground=fg_color)

        self.update()


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Main entry point."""
    try:
        app = HarnessDashboard()
        app.mainloop()
    except Exception as e:
        logger.error("Dashboard error: %s", e)
        messagebox.showerror("Error", f"Dashboard failed to start: {e}")


if __name__ == "__main__":
    main()
