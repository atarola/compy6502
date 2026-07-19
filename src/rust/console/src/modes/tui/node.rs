const NODE_CAP: usize = 64;

#[derive(Clone, Copy, Default)]
pub struct Node {
    pub kind: u8,
    pub state: u8,
    pub parent: u8,
    pub first_child: u8,
    pub next_sibling: u8,
    pub prev_sibling: u8,
}

#[derive(Clone)]
pub struct NodeTable {
    nodes: [Node; NODE_CAP],
}

impl NodeTable {
    pub fn new() -> NodeTable {
        NodeTable {
            nodes: [Node::default(); NODE_CAP],
        }
    }

    pub fn root(&self) -> Node {
        self.nodes[0]
    }
}
