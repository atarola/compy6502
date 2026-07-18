const NODE_COUNT: usize = 64;
const PROP_COUNT: usize = 5;
const NODE_FREE: u8 = 0x00;
const NODE_ROOT: u8 = 0xFF;

#[derive(Clone, Copy)]
struct Node {
    kind: u8,
    parent: u8,
    first_child: u8,
    next_sibling: u8,
    text_len: u16,
    props: [u16; PROP_COUNT],
}

#[derive(Clone, Copy)]
pub struct Tree {
    nodes: [Node; NODE_COUNT],
}

impl Node {
    const fn empty() -> Node {
        Node {
            kind: NODE_FREE,
            parent: 0,
            first_child: 0,
            next_sibling: 0,
            text_len: 0,
            props: [0; PROP_COUNT],
        }
    }

    const fn root() -> Node {
        Node {
            kind: NODE_ROOT,
            parent: 0,
            first_child: 0,
            next_sibling: 0,
            text_len: 0,
            props: [0; PROP_COUNT],
        }
    }

    fn is_free(&self) -> bool {
        self.kind == NODE_FREE
    }
}

impl Tree {
    pub fn new() -> Tree {
        let mut tree = Tree {
            nodes: [Node::empty(); NODE_COUNT],
        };
        tree.nodes[0] = Node::root();
        tree
    }

    pub fn create(&mut self, handle: u8, parent: u8, kind: u8) {
        if !self.valid_handle(handle) || handle == 0 || !self.occupied(parent) || kind == NODE_FREE
        {
            return;
        }

        self.remove(handle);
        self.nodes[handle as usize] = Node {
            kind,
            parent,
            first_child: 0,
            next_sibling: self.nodes[parent as usize].first_child,
            text_len: 0,
            props: [0; PROP_COUNT],
        };
        self.nodes[parent as usize].first_child = handle;
    }

    pub fn remove(&mut self, handle: u8) {
        if !self.valid_handle(handle) || handle == 0 || self.nodes[handle as usize].is_free() {
            return;
        }

        self.detach(handle);
        self.remove_subtree(handle);
    }

    pub fn set_prop(&mut self, handle: u8, key: u8, value: u8) {
        if !self.occupied(handle) || key == 0 {
            return;
        }

        let node = &mut self.nodes[handle as usize];
        for prop in node.props.iter_mut() {
            let prop_key = (*prop >> 8) as u8;
            if prop_key == key || prop_key == 0 {
                *prop = ((key as u16) << 8) | value as u16;
                return;
            }
        }
    }

    pub fn set_text_len(&mut self, handle: u8, len: u16) {
        if self.occupied(handle) {
            self.nodes[handle as usize].text_len = len;
        }
    }

    fn valid_handle(&self, handle: u8) -> bool {
        (handle as usize) < NODE_COUNT
    }

    fn occupied(&self, handle: u8) -> bool {
        self.valid_handle(handle) && !self.nodes[handle as usize].is_free()
    }

    fn detach(&mut self, handle: u8) {
        let parent = self.nodes[handle as usize].parent;
        if !self.occupied(parent) {
            return;
        }

        let mut child = self.nodes[parent as usize].first_child;
        let mut prev = 0;
        while child != 0 {
            if child == handle {
                let next = self.nodes[child as usize].next_sibling;
                if prev == 0 {
                    self.nodes[parent as usize].first_child = next;
                } else {
                    self.nodes[prev as usize].next_sibling = next;
                }
                return;
            }
            prev = child;
            child = self.nodes[child as usize].next_sibling;
        }
    }

    fn remove_subtree(&mut self, handle: u8) {
        let mut child = self.nodes[handle as usize].first_child;
        while child != 0 {
            let next = self.nodes[child as usize].next_sibling;
            self.remove_subtree(child);
            child = next;
        }
        self.nodes[handle as usize] = Node::empty();
    }
}
