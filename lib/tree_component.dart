library tree_component;

import 'dart:html';

class TreeComponent {

  List<TreeNode> _roots;

  TreeComponent(TreeNode roots) {
    _roots = [roots] ;
  }
  
  TreeComponent.multipleRoots(this._roots);

  TreeNode getNodeByID(String id) {
    for (var root in roots) {
      var found = root.getNodeByID(id) ;
      if (found != null) return found ;
    }
    return null ;
  }
  
  Element _parentElement;
  int _margin ;

  int get margin => _margin ;
  set margin(int size) => _margin = size != null ? ( size >= 0 ? size : 0 ) : DEFAULT_MARGIN ; 

  static const int DEFAULT_MARGIN = 16 ;
  
  List<TreeNode> get roots => new List.from( _roots ) ;
  int get rootsSize => _roots.length ;
  bool get hasMultipleRoots => roots.length > 1 ;
  
  void buildAt(Element parentElement,[int margin = DEFAULT_MARGIN]) {
    if (this._parentElement != null) remove();

    this._parentElement = parentElement;
    this._margin = margin != null ? margin : DEFAULT_MARGIN ;

    _buildTree(parentElement);
  }
  
  void rebuild() {
    _buildTree(this._parentElement);
  }
  
  UListElement _elemUlRoot ;
  
  void _buildTree(Element parentElement) {
    
    if (_elemUlRoot != null) {
      _elemUlRoot.remove() ;
    }
    
    _elemUlRoot = new UListElement();
    _elemUlRoot.style.listStyleType = 'none';
    _elemUlRoot.style.paddingLeft = "0px";

    parentElement.children.add(_elemUlRoot);
   
    for (var root in _roots) {
      _buildNode(_elemUlRoot, root) ;
    }
    
  }
  
  void _buildNode(Element parentElement, TreeNode node) {
    
    if ( node.isHidden ) {
      return ;
    }
    
    if ( node._component != null ) {
      node._component.remove() ;
    }
    
    UListElement elem = new UListElement();
    elem.style.listStyleType = 'none';
    
    int margin = 0 ;
    
    if (!node.hasChildren) margin += 8 ;
    
    if (margin > 0) {
      elem.style.marginLeft = "${margin}px";
    }
    
    //elem.style.paddingLeft = "${_margin}px";

    node._treeElement = elem;

    var nodeComponent = new TreeNodeComponent(this, node);
    node._component = nodeComponent;

    elem.children.add(nodeComponent.element);

    parentElement.children.add(elem);

    _buildNodeChildren(node);

  }

  void _buildNodeChildren(TreeNode node) {

    if (node.isExpanded) {

      for (var subNode in node._children) {
        _buildNode(node._treeElement, subNode);
      }

    }

  }

  void remove() {
    if (this._parentElement == null) return;
    
    if (_elemUlRoot != null) {
      _elemUlRoot.remove() ;
      _elemUlRoot = null ;
    }

    for (var root in _roots) {
      _removeNode(root);  
    }
  }

  void _removeNode(TreeNode node) {

    _removeNodeChildren(node);

    if (node._component != null) {
      node._component.remove();
      node._component = null;
    }

  }

  void _removeNodeChildren(TreeNode node) {

    for (var subNode in node._children) {
      _removeNode(subNode);
    }

  }

}


class TreeNodeComponent {
  
  static String _ARROW_RIGHT =  "▶&nbsp;" ;
  static String _ARROW_DOWN = "▼&nbsp;" ;
  
  TreeComponent _treeComponent;

  TreeNode _node;
  LIElement _element;

  TreeNodeComponent(this._treeComponent, this._node) {
    _build();
  }

  Element get element => _element;

  void _build() {
    this._element = new LIElement();
    buildContent();
  }

  void buildContent() {

    for (var child in new List.from(_element.children)) {
      child.remove();
    }

    if (_node.hasChildren) {
      SpanElement arrow = new SpanElement()
      ..innerHtml = ( _node.isExpanded ? _ARROW_DOWN : _ARROW_RIGHT) ;
      
      _element.children.add(arrow);
      
      arrow.onClick.listen((L) {
        if (_node.isExpanded) {
          _node.expanded = false;
          _treeComponent._removeNodeChildren(_node);
          buildContent();
        } else {
          _node.expanded = true;
          _treeComponent._buildNodeChildren(_node);
          buildContent();
        }
        //TODO null nos listeners
        if(_node.listener != null)
        _node.listener.onExpandAction(_node);
      });
    }
    else {
      
    }

    SpanElement spanElementName = new SpanElement()
    ..text = _node.label;
    
    spanElementName.onClick.listen((L){
      if(_node.listener != null)
      _node.listener.onClickAction(_node);
    });

    if(_node.properties['color']!=null){
      DivElement colorLabel = new DivElement()
      ..id="color"
      ..style.backgroundColor=_node.properties['color']
      //..style.htmlFor=checkBox.id
      ..style.margin="3px"
      ..style.width ="10px"
      ..style.height ="10px"
      ..style.fontSize="30%"
      ..style.display="inline-block"
      ..style.verticalAlign="7px"
      ..style.borderRadius= '5px'
      ..setInnerHtml("&nbsp;")
      ;
      _element.children.add(colorLabel);
    }
    _element.children.add(spanElementName); //TODO adicionar listener aqui!

  }

  void remove() {
    _element.remove();
    _element = null;
  }

}


class TreeNode {
  String label;
  Map properties;
  String id;

  TreeNode _parent;
  List<TreeNode> _children = [];

  bool _hidden = false ;
  
  bool _expanded ;
  bool _checked ;

  TreeNode.root(this.label, this.id, [this.properties,this._checked = true, this._expanded = true ]) {
    checkInit();
  }

  TreeNode.node(this._parent, this.label, this.id, [this.properties, this._checked = false, this._expanded = false]) {
    checkInit();
    _parent._children.add(this);
  }

  void checkInit() {
    if (this._checked == null) this._checked = false;
    if (this._expanded == null) this._expanded = false;
    if (this.properties == null) this.properties = {};
  }

  bool get isRoot => _parent == null;
  bool get isParent => hasChildren;
  bool get hasChildren => _children.isNotEmpty;
  bool get isExpanded => _expanded;
  bool get isChecked => _checked;
  
  bool get isHidden => _hidden ;
  
  TreeNode getNodeByID(String id) {
    if ( this.id == id ) return this ;
    
    for (var node in _children) {
      var found = node.getNodeByID(id) ;
      if (found != null) return found ;
    }
    
    return null ;
  }
  
  List<TreeNode> getAllSubNodes( [bool addThisNode = true] ){
    List<TreeNode> all = [] ;
    
    if (addThisNode) all.add(this) ;
    
    _addAllSubNodes(all) ;
    
    return all ;
  }
  
  void _addAllSubNodes(List<TreeNode> all){
    for (var node in _children) {
      all.add(node) ;
      node._addAllSubNodes(all) ;
    }
  }
  
  set checked(bool checked) {
    _checked = checked;
        
    if(_component !=null && _component.checkBox != null) {
      this._component.checkBox.checked = _checked;
    }  
  }
  
  set expanded(bool expanded) => _expanded = expanded;
  set hidden(bool hidden) => _hidden = hidden;
  
  List<TreeNode> get children => _children;

  TreeNode get parent => _parent;

  TreeNode getRoot() {
    TreeNode cursor = this;
    do {
      if (cursor.isRoot) return cursor;
      cursor = cursor.parent;
    } while (cursor != null);

    throw new StateError("Invalid tree structure");
  }

  TreeNode createChild(String name, String id, [Map properties, bool expanded = false]) {
    var child = new TreeNode.node(this, name, id, properties, expanded);
    return child;
  }

  /////////

  TreeNodeListener listener;

  /////////

  Element _treeElement;
  TreeNodeComponent _component;

  /////////

  Map<String, Object> toJson() => {
    "data": properties
  };

}

abstract class TreeNodeListener {

  onCheckAction(TreeNode node);
  onExpandAction(TreeNode node);
  onClickAction(TreeNode node);

}
