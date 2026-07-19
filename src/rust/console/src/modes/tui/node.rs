const NODE_CAP: usize = 64;
pub const NO_NODE: u8 = 0xFF;

#[derive(Clone, Copy, Default)]
pub struct Node {
    pub kind: u8,
    pub state: u8,
    pub parent: u8,
    pub first_child: u8,
    pub next_sibling: u8,
    pub prev_sibling: u8,
}

impl Node {
    pub const fn free() -> Node {
        Node {
            kind: 0,
            state: 0,
            parent: NO_NODE,
            first_child: NO_NODE,
            next_sibling: NO_NODE,
            prev_sibling: NO_NODE,
        }
    }

    pub const fn root() -> Node {
        Node {
            kind: 0,
            state: 0,
            parent: 0,
            first_child: NO_NODE,
            next_sibling: NO_NODE,
            prev_sibling: NO_NODE,
        }
    }
}

#[derive(Clone)]
pub struct NodeTable {
    nodes: [Node; NODE_CAP],
}

impl NodeTable {
    pub fn new() -> NodeTable {
        let mut nodes = [Node::free(); NODE_CAP];
        nodes[0] = Node::root();
        NodeTable { nodes }
    }

    pub fn root(&self) -> Node {
        self.nodes[0]
    }

    pub fn node(&self, handle: u8) -> Node {
        self.nodes[handle as usize]
    }

    fn is_occupied(&self, handle: u8) -> bool {
        handle == 0 || self.nodes[handle as usize].parent != NO_NODE
    }

    fn unlink(&mut self, handle: u8) {
        let node = self.nodes[handle as usize];

        if node.prev_sibling != NO_NODE {
            self.nodes[node.prev_sibling as usize].next_sibling = node.next_sibling;
        } else if node.parent != NO_NODE {
            self.nodes[node.parent as usize].first_child = node.next_sibling;
        }

        if node.next_sibling != NO_NODE {
            self.nodes[node.next_sibling as usize].prev_sibling = node.prev_sibling;
        }
    }

    fn clear_node(&mut self, handle: u8) {
        self.nodes[handle as usize] = Node::free();
    }

    pub fn destroy(&mut self, handle: u8) {
        if handle == 0 || !self.is_occupied(handle) {
            return;
        }

        let mut child = self.nodes[handle as usize].first_child;
        while child != NO_NODE {
            let next = self.nodes[child as usize].next_sibling;
            self.destroy(child);
            child = next;
        }

        self.unlink(handle);
        self.clear_node(handle);
    }

    pub fn create(&mut self, kind: u8, handle: u8, parent: u8) -> bool {
        if handle == 0 || handle as usize >= NODE_CAP || parent as usize >= NODE_CAP {
            return false;
        }

        if self.is_occupied(handle) {
            self.destroy(handle);
        }

        let old_first = self.nodes[parent as usize].first_child;
        self.nodes[handle as usize] = Node {
            kind,
            state: 0,
            parent,
            first_child: NO_NODE,
            next_sibling: old_first,
            prev_sibling: NO_NODE,
        };

        if old_first != NO_NODE {
            self.nodes[old_first as usize].prev_sibling = handle;
        }

        self.nodes[parent as usize].first_child = handle;
        true
    }
}
