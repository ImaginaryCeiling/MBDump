# MBDump Data Storage & API Integration Guide

This document provides a comprehensive overview of how MBDump currently stores data and how to make it accessible via APIs and databases for multi-client support.

## Table of Contents

1. [Current Data Storage](#current-data-storage)
2. [Data Structure](#data-structure)
3. [JSON Schema](#json-schema)
4. [Making Data API-Ready](#making-data-api-ready)
5. [Database Schema Recommendations](#database-schema-recommendations)
6. [API Design Recommendations](#api-design-recommendations)
7. [Migration Strategy](#migration-strategy)
8. [Implementation Examples](#implementation-examples)

---

## Current Data Storage

### Storage Mechanism

MBDump currently uses a **single-file JSON storage** approach:

- **Location**: `~/Documents/mbdump_data.json`
- **Format**: JSON (UTF-8 encoded)
- **Encoding**: Swift's `Codable` protocol with `JSONEncoder`/`JSONDecoder`
- **Persistence**: Synchronous write on every data mutation
- **Structure**: Root-level array of `Canvas` objects

### Storage Implementation Details

The storage is managed by the `DataStore` class (`MBDump/Models/DataStore.swift`):

```swift
// Save location
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
saveURL = documentsPath.appendingPathComponent("mbdump_data.json")

// Save operation (called on every mutation)
private func save() {
    do {
        let data = try JSONEncoder().encode(canvases)
        try data.write(to: saveURL)
    } catch {
        print("Failed to save: \(error)")
    }
}

// Load operation (called on app initialization)
private func load() {
    do {
        let data = try Data(contentsOf: saveURL)
        canvases = try JSONDecoder().decode([Canvas].self, from: data)
    } catch {
        print("Failed to load (might be first run): \(error)")
    }
}
```

### Characteristics

**Advantages:**
- ✅ Simple and portable
- ✅ Human-readable format
- ✅ No external dependencies
- ✅ Easy to backup and restore
- ✅ Works offline

**Limitations:**
- ❌ Single-file bottleneck (all data loaded into memory)
- ❌ No concurrent access support
- ❌ No querying capabilities
- ❌ No versioning or history
- ❌ No multi-user support
- ❌ Synchronous writes can block UI
- ❌ No data validation or constraints
- ❌ Limited scalability

---

## Data Structure

### Entity Relationship Model

```
Canvas (Root Entity)
├── id: UUID
├── name: String
├── items: [Item]
├── children: [Canvas] (nested canvases/folders)
├── isFolder: Bool
├── type: CanvasType? (todo | articles)
└── tags: [String]

Item (Child Entity)
├── id: UUID
├── content: String
├── type: ItemType (text | link | file)
├── createdAt: Date
├── title: String? (for links)
├── isCompleted: Bool (for todo items)
└── notes: String? (for article notes)
```

### Hierarchical Structure

Canvases support a **nested folder structure**:
- Root level: Array of top-level canvases
- Nested: Each canvas can have `children` (other canvases)
- Folders: Canvases with `isFolder: true` act as containers
- Items: Belong to a specific canvas (not nested)

**Example Structure:**
```
Root
├── Inbox (Canvas)
│   ├── Item 1
│   └── Item 2
├── Folder 1 (Canvas, isFolder: true)
│   └── Reading List (Canvas)
│       └── Item 3
└── Todo List (Canvas, type: todo)
    ├── Item 4 (isCompleted: false)
    └── Item 5 (isCompleted: true)
```

### Data Types

#### CanvasType Enum
```swift
enum CanvasType: String, Codable {
    case todo = "todo"
    case articles = "articles"
}
```

#### ItemType Enum
```swift
enum ItemType: Codable {
    case text
    case link
    case file
}
```

#### Canvas Model
```swift
struct Canvas: Identifiable, Codable {
    var id: UUID
    var name: String
    var items: [Item]
    var children: [Canvas]
    var isFolder: Bool
    var type: CanvasType?
    var tags: [String]
}
```

#### Item Model
```swift
struct Item: Identifiable, Codable {
    let id: UUID
    var content: String
    var type: ItemType
    var createdAt: Date
    var title: String?
    var isCompleted: Bool
    var notes: String?
}
```

---

## JSON Schema

### Example JSON Structure

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Inbox",
    "items": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "content": "https://example.com/article",
        "type": {
          "link": {}
        },
        "createdAt": "2024-01-15T10:30:00Z",
        "title": "Example Article",
        "isCompleted": false,
        "notes": null
      },
      {
        "id": "660e8400-e29b-41d4-a716-446655440002",
        "content": "Remember to buy milk",
        "type": {
          "text": {}
        },
        "createdAt": "2024-01-15T11:00:00Z",
        "title": null,
        "isCompleted": false,
        "notes": null
      }
    ],
    "children": [],
    "isFolder": false,
    "type": null,
    "tags": []
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "name": "Folder 1",
    "items": [],
    "children": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440004",
        "name": "Reading List",
        "items": [],
        "children": [],
        "isFolder": false,
        "type": "articles",
        "tags": ["books", "reading"]
      }
    ],
    "isFolder": true,
    "type": null,
    "tags": []
  }
]
```

### JSON Encoding Notes

- **UUIDs**: Encoded as strings in standard UUID format
- **Dates**: Encoded as ISO 8601 strings (e.g., "2024-01-15T10:30:00Z")
- **Enums**: 
  - `ItemType`: Encoded as objects with a single key (e.g., `{"link": {}}`, `{"text": {}}`, `{"file": {}}`)
  - `CanvasType`: Encoded as strings ("todo" or "articles")
- **Optional Fields**: Omitted if `nil` (Swift's default JSON encoding behavior)

---

## Making Data API-Ready

### Current Limitations for API Access

1. **File-based storage**: Not accessible over network
2. **No REST endpoints**: No HTTP interface
3. **No authentication**: No user management
4. **No versioning**: No change tracking
5. **No concurrent access**: Single-writer limitation
6. **No querying**: Can't filter/search efficiently

### Required Changes

To make MBDump data accessible via API, you need to:

1. **Add a backend service** (API server)
2. **Migrate to a database** (or add database layer)
3. **Implement REST/GraphQL API**
4. **Add authentication/authorization**
5. **Handle concurrent access**
6. **Add data validation**

---

## Database Schema Recommendations

### Option 1: Relational Database (PostgreSQL/MySQL/SQLite)

#### Schema Design

```sql
-- Users table (for multi-user support)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Canvases table (with self-referential foreign key for hierarchy)
CREATE TABLE canvases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES canvases(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    is_folder BOOLEAN DEFAULT FALSE,
    type VARCHAR(20) CHECK (type IN ('todo', 'articles')),
    position INTEGER DEFAULT 0, -- For ordering
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_parent_id (parent_id)
);

-- Canvas tags (many-to-many relationship)
CREATE TABLE canvas_tags (
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    PRIMARY KEY (canvas_id, tag),
    INDEX idx_tag (tag)
);

-- Items table
CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    canvas_id UUID NOT NULL REFERENCES canvases(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('text', 'link', 'file')),
    title VARCHAR(500),
    is_completed BOOLEAN DEFAULT FALSE,
    notes TEXT,
    position INTEGER DEFAULT 0, -- For ordering within canvas
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_canvas_id (canvas_id),
    INDEX idx_type (type),
    INDEX idx_is_completed (is_completed),
    INDEX idx_created_at (created_at)
);

-- Full-text search index (for PostgreSQL)
CREATE INDEX idx_items_content_fts ON items USING gin(to_tsvector('english', content));
CREATE INDEX idx_items_title_fts ON items USING gin(to_tsvector('english', COALESCE(title, '')));
```

#### Migration Script (JSON to Database)

```python
import json
import uuid
from datetime import datetime
import psycopg2

def migrate_json_to_db(json_file_path, db_connection, user_id):
    """
    Migrate existing JSON data to database
    """
    with open(json_file_path, 'r') as f:
        canvases = json.load(f)
    
    cursor = db_connection.cursor()
    
    def insert_canvas(canvas_data, parent_id=None, position=0):
        canvas_id = uuid.UUID(canvas_data['id'])
        
        # Insert canvas
        cursor.execute("""
            INSERT INTO canvases (id, user_id, parent_id, name, is_folder, type, position)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            canvas_id,
            user_id,
            parent_id,
            canvas_data['name'],
            canvas_data.get('isFolder', False),
            canvas_data.get('type'),
            position
        ))
        
        # Insert tags
        for tag in canvas_data.get('tags', []):
            cursor.execute("""
                INSERT INTO canvas_tags (canvas_id, tag)
                VALUES (%s, %s)
            """, (canvas_id, tag))
        
        # Insert items
        for idx, item_data in enumerate(canvas_data.get('items', [])):
            item_id = uuid.UUID(item_data['id'])
            item_type = item_data['type']
            # Convert enum object to string
            if 'link' in item_type:
                item_type_str = 'link'
            elif 'file' in item_type:
                item_type_str = 'file'
            else:
                item_type_str = 'text'
            
            cursor.execute("""
                INSERT INTO items (id, canvas_id, content, type, title, is_completed, notes, position, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                item_id,
                canvas_id,
                item_data['content'],
                item_type_str,
                item_data.get('title'),
                item_data.get('isCompleted', False),
                item_data.get('notes'),
                idx,
                datetime.fromisoformat(item_data['createdAt'].replace('Z', '+00:00'))
            ))
        
        # Insert children recursively
        for idx, child in enumerate(canvas_data.get('children', [])):
            insert_canvas(child, parent_id=canvas_id, position=idx)
    
    # Insert all root canvases
    for idx, canvas in enumerate(canvases):
        insert_canvas(canvas, parent_id=None, position=idx)
    
    db_connection.commit()
```

### Option 2: NoSQL Database (MongoDB)

#### Document Structure

```javascript
// Users collection
{
  _id: ObjectId("..."),
  email: "user@example.com",
  name: "User Name",
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-01-15T10:30:00Z")
}

// Canvases collection (with embedded items)
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),
  parentId: ObjectId("..."), // null for root
  name: "Inbox",
  isFolder: false,
  type: "todo", // or "articles" or null
  tags: ["tag1", "tag2"],
  items: [
    {
      id: UUID("..."),
      content: "https://example.com",
      type: "link",
      title: "Example",
      isCompleted: false,
      notes: null,
      createdAt: ISODate("2024-01-15T10:30:00Z"),
      updatedAt: ISODate("2024-01-15T10:30:00Z")
    }
  ],
  position: 0,
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-01-15T10:30:00Z")
}

// Indexes
db.canvases.createIndex({ userId: 1, parentId: 1 });
db.canvases.createIndex({ userId: 1, "items.id": 1 });
db.canvases.createIndex({ userId: 1, tags: 1 });
db.canvases.createIndex({ userId: 1, type: 1 });
db.canvases.createIndex({ userId: 1, name: "text", "items.content": "text" });
```

### Option 3: Hybrid Approach (SQLite + JSON)

For a simpler migration path, you could:

1. Keep JSON file as primary storage
2. Add SQLite database for indexing and querying
3. Sync between JSON and SQLite on changes
4. Use SQLite for API queries, JSON for file-based access

---

## API Design Recommendations

### REST API Endpoints

#### Authentication
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me
```

#### Canvases
```
GET    /api/canvases                    # List all canvases (with optional filters)
GET    /api/canvases/:id                # Get canvas by ID
POST   /api/canvases                    # Create new canvas
PATCH  /api/canvases/:id                # Update canvas
DELETE /api/canvases/:id                # Delete canvas
POST   /api/canvases/:id/move           # Move canvas to different parent
GET    /api/canvases/:id/items          # Get all items in canvas
```

#### Items
```
GET    /api/items                       # List items (with filters)
GET    /api/items/:id                   # Get item by ID
POST   /api/items                       # Create new item
PATCH  /api/items/:id                   # Update item
DELETE /api/items/:id                   # Delete item
POST   /api/items/:id/move              # Move item to different canvas
PATCH  /api/items/:id/complete          # Toggle completion status
```

#### Search & Queries
```
GET    /api/search?q=query              # Full-text search
GET    /api/items?canvas_id=:id         # Filter items by canvas
GET    /api/items?type=link             # Filter items by type
GET    /api/items?completed=false       # Filter by completion status
GET    /api/canvases?tag=:tag           # Filter canvases by tag
GET    /api/canvases?type=todo          # Filter canvases by type
```

### GraphQL API Alternative

```graphql
type Query {
  me: User
  canvas(id: ID!): Canvas
  canvases(filter: CanvasFilter): [Canvas!]!
  item(id: ID!): Item
  items(filter: ItemFilter): [Item!]!
  search(query: String!): SearchResults!
}

type Mutation {
  createCanvas(input: CreateCanvasInput!): Canvas!
  updateCanvas(id: ID!, input: UpdateCanvasInput!): Canvas!
  deleteCanvas(id: ID!): Boolean!
  
  createItem(input: CreateItemInput!): Item!
  updateItem(id: ID!, input: UpdateItemInput!): Item!
  deleteItem(id: ID!): Boolean!
  moveItem(id: ID!, canvasId: ID!): Item!
  toggleItemCompletion(id: ID!): Item!
}

type Canvas {
  id: ID!
  name: String!
  items: [Item!]!
  children: [Canvas!]!
  isFolder: Boolean!
  type: CanvasType
  tags: [String!]!
  parent: Canvas
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Item {
  id: ID!
  content: String!
  type: ItemType!
  title: String
  isCompleted: Boolean!
  notes: String
  canvas: Canvas!
  createdAt: DateTime!
  updatedAt: DateTime!
}

enum CanvasType {
  TODO
  ARTICLES
}

enum ItemType {
  TEXT
  LINK
  FILE
}
```

### API Response Format

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Inbox",
    "items": [...],
    "children": [...],
    "isFolder": false,
    "type": "todo",
    "tags": ["tag1", "tag2"],
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  },
  "meta": {
    "version": "1.0",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### Error Response Format

```json
{
  "error": {
    "code": "CANVAS_NOT_FOUND",
    "message": "Canvas with ID 'xxx' not found",
    "details": {}
  }
}
```

---

## Migration Strategy

### Phase 1: Dual-Write (Backward Compatible)

1. Keep existing JSON file storage
2. Add database layer alongside JSON
3. Write to both JSON and database on mutations
4. Read from database for API, JSON for macOS app
5. Implement sync mechanism

**Implementation:**
```swift
class DataStore: ObservableObject {
    private let jsonStore: JSONDataStore
    private let dbStore: DatabaseStore?
    
    func save() {
        jsonStore.save(canvases)  // Existing
        dbStore?.save(canvases)    // New
    }
}
```

### Phase 2: Database-First (Gradual Migration)

1. Make database the source of truth
2. JSON file becomes a backup/export format
3. macOS app reads from database via local API or direct DB access
4. Remove JSON writes after validation period

### Phase 3: Full API Integration

1. macOS app communicates via API (local or remote)
2. All clients use same API
3. JSON file only for exports/backups
4. Enable multi-device sync

### Migration Checklist

- [ ] Set up database (PostgreSQL/MongoDB/SQLite)
- [ ] Create database schema
- [ ] Write migration script (JSON → Database)
- [ ] Implement database access layer
- [ ] Add API server (Express.js, Flask, etc.)
- [ ] Implement authentication
- [ ] Create REST/GraphQL endpoints
- [ ] Add data validation
- [ ] Implement error handling
- [ ] Add API client to macOS app
- [ ] Test migration with existing data
- [ ] Add backup/export functionality
- [ ] Document API endpoints
- [ ] Add rate limiting and security
- [ ] Enable CORS for web clients
- [ ] Add WebSocket support for real-time updates (optional)

---

## Implementation Examples

### Example 1: Node.js/Express API Server

```javascript
// server.js
const express = require('express');
const { Pool } = require('pg');
const app = express();

const pool = new Pool({
  user: 'mbdump',
  host: 'localhost',
  database: 'mbdump',
  password: 'password',
  port: 5432,
});

app.use(express.json());

// Get all canvases for user
app.get('/api/canvases', async (req, res) => {
  try {
    const userId = req.user.id; // From auth middleware
    const result = await pool.query(`
      SELECT * FROM canvases 
      WHERE user_id = $1 AND parent_id IS NULL
      ORDER BY position
    `, [userId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get canvas with items
app.get('/api/canvases/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    // Get canvas
    const canvasResult = await pool.query(`
      SELECT * FROM canvases WHERE id = $1 AND user_id = $2
    `, [id, userId]);
    
    if (canvasResult.rows.length === 0) {
      return res.status(404).json({ error: 'Canvas not found' });
    }
    
    const canvas = canvasResult.rows[0];
    
    // Get items
    const itemsResult = await pool.query(`
      SELECT * FROM items 
      WHERE canvas_id = $1 
      ORDER BY position
    `, [id]);
    
    // Get tags
    const tagsResult = await pool.query(`
      SELECT tag FROM canvas_tags WHERE canvas_id = $1
    `, [id]);
    
    // Get children
    const childrenResult = await pool.query(`
      SELECT * FROM canvases 
      WHERE parent_id = $1 
      ORDER BY position
    `, [id]);
    
    canvas.items = itemsResult.rows;
    canvas.tags = tagsResult.rows.map(r => r.tag);
    canvas.children = childrenResult.rows;
    
    res.json(canvas);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create item
app.post('/api/items', async (req, res) => {
  try {
    const { canvas_id, content, type, title, notes } = req.body;
    const userId = req.user.id;
    
    // Verify canvas belongs to user
    const canvasCheck = await pool.query(`
      SELECT id FROM canvases WHERE id = $1 AND user_id = $2
    `, [canvas_id, userId]);
    
    if (canvasCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Canvas not found' });
    }
    
    const result = await pool.query(`
      INSERT INTO items (canvas_id, content, type, title, notes, position)
      VALUES ($1, $2, $3, $4, $5, 
        (SELECT COALESCE(MAX(position), -1) + 1 FROM items WHERE canvas_id = $1))
      RETURNING *
    `, [canvas_id, content, type, title, notes]);
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('API server running on port 3000');
});
```

### Example 2: Swift API Client

```swift
// APIClient.swift
import Foundation

class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?
    
    init(baseURL: URL = URL(string: "http://localhost:3000")!) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func getCanvases() async throws -> [Canvas] {
        return try await request(endpoint: "/api/canvases")
    }
    
    func getCanvas(id: UUID) async throws -> Canvas {
        return try await request(endpoint: "/api/canvases/\(id.uuidString)")
    }
    
    func createItem(canvasId: UUID, content: String, type: ItemType) async throws -> Item {
        struct CreateItemRequest: Encodable {
            let canvas_id: String
            let content: String
            let type: String
        }
        
        let typeString: String
        switch type {
        case .text: typeString = "text"
        case .link: typeString = "link"
        case .file: typeString = "file"
        }
        
        let requestBody = CreateItemRequest(
            canvas_id: canvasId.uuidString,
            content: content,
            type: typeString
        )
        
        return try await request(endpoint: "/api/items", method: "POST", body: requestBody)
    }
}

enum APIError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
}
```

### Example 3: Python Migration Script

```python
#!/usr/bin/env python3
"""
Migrate MBDump JSON data to PostgreSQL database
Usage: python migrate.py <json_file_path> <user_email>
"""

import json
import sys
import uuid
from datetime import datetime
import psycopg2
from psycopg2.extras import execute_values

def migrate(json_path, user_email, db_config):
    """Migrate JSON file to database"""
    
    # Load JSON data
    with open(json_path, 'r') as f:
        canvases_data = json.load(f)
    
    # Connect to database
    conn = psycopg2.connect(**db_config)
    cur = conn.cursor()
    
    try:
        # Get or create user
        cur.execute("SELECT id FROM users WHERE email = %s", (user_email,))
        user_row = cur.fetchone()
        if user_row:
            user_id = user_row[0]
        else:
            user_id = uuid.uuid4()
            cur.execute(
                "INSERT INTO users (id, email, name) VALUES (%s, %s, %s)",
                (user_id, user_email, user_email.split('@')[0])
            )
        
        def process_canvas(canvas_data, parent_id=None, position=0):
            """Recursively process canvas and its children"""
            canvas_id = uuid.UUID(canvas_data['id'])
            
            # Insert canvas
            cur.execute("""
                INSERT INTO canvases 
                (id, user_id, parent_id, name, is_folder, type, position, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            """, (
                canvas_id,
                user_id,
                parent_id,
                canvas_data['name'],
                canvas_data.get('isFolder', False),
                canvas_data.get('type'),
                position
            ))
            
            # Insert tags
            if canvas_data.get('tags'):
                tag_values = [(canvas_id, tag) for tag in canvas_data['tags']]
                execute_values(
                    cur,
                    "INSERT INTO canvas_tags (canvas_id, tag) VALUES %s",
                    tag_values
                )
            
            # Insert items
            if canvas_data.get('items'):
                item_values = []
                for idx, item_data in enumerate(canvas_data['items']):
                    item_id = uuid.UUID(item_data['id'])
                    item_type = item_data['type']
                    
                    # Convert enum object to string
                    if isinstance(item_type, dict):
                        if 'link' in item_type:
                            item_type_str = 'link'
                        elif 'file' in item_type:
                            item_type_str = 'file'
                        else:
                            item_type_str = 'text'
                    else:
                        item_type_str = item_type
                    
                    created_at = datetime.fromisoformat(
                        item_data['createdAt'].replace('Z', '+00:00')
                    )
                    
                    item_values.append((
                        item_id,
                        canvas_id,
                        item_data['content'],
                        item_type_str,
                        item_data.get('title'),
                        item_data.get('isCompleted', False),
                        item_data.get('notes'),
                        idx,
                        created_at,
                        created_at
                    ))
                
                execute_values(
                    cur,
                    """INSERT INTO items 
                    (id, canvas_id, content, type, title, is_completed, notes, position, created_at, updated_at)
                    VALUES %s""",
                    item_values
                )
            
            # Process children
            for idx, child in enumerate(canvas_data.get('children', [])):
                process_canvas(child, parent_id=canvas_id, position=idx)
        
        # Process all root canvases
        for idx, canvas in enumerate(canvases_data):
            process_canvas(canvas, parent_id=None, position=idx)
        
        conn.commit()
        print(f"✅ Successfully migrated {len(canvases_data)} canvases for user {user_email}")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error during migration: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python migrate.py <json_file_path> <user_email>")
        sys.exit(1)
    
    json_path = sys.argv[1]
    user_email = sys.argv[2]
    
    db_config = {
        'host': 'localhost',
        'database': 'mbdump',
        'user': 'mbdump',
        'password': 'password'
    }
    
    migrate(json_path, user_email, db_config)
```

---

## Additional Considerations

### Security

- **Authentication**: Use JWT tokens or OAuth 2.0
- **Authorization**: Ensure users can only access their own data
- **Input Validation**: Validate all API inputs
- **SQL Injection**: Use parameterized queries
- **Rate Limiting**: Prevent abuse
- **HTTPS**: Always use encrypted connections in production

### Performance

- **Indexing**: Add indexes on frequently queried fields
- **Pagination**: Implement pagination for large result sets
- **Caching**: Use Redis for frequently accessed data
- **Connection Pooling**: Reuse database connections
- **Lazy Loading**: Load nested data on demand

### Scalability

- **Horizontal Scaling**: Use load balancers
- **Database Replication**: Read replicas for scaling reads
- **CDN**: Serve static assets via CDN
- **Message Queue**: Use queues for async operations (e.g., fetching link titles)

### Data Consistency

- **Transactions**: Use database transactions for multi-step operations
- **Optimistic Locking**: Handle concurrent updates
- **Event Sourcing**: Consider for audit trails (optional)
- **Backup Strategy**: Regular automated backups

---

## Conclusion

MBDump currently uses a simple JSON file storage that works well for single-user, single-device scenarios. To enable API access and multi-client support:

1. **Short-term**: Add a local API server that reads/writes the JSON file
2. **Medium-term**: Migrate to a database (SQLite for local, PostgreSQL for production)
3. **Long-term**: Full API infrastructure with authentication, multi-user support, and sync

The migration can be done incrementally without breaking existing functionality, allowing for a smooth transition to a more scalable architecture.

