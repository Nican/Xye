part of xye;



bool elementInViewport(el, parent) {
  if(!document.contains(el) || !document.contains(parent))
    return false;
  
  var top = el.offsetTop;
  var left = el.offsetLeft;
  var width = el.offsetWidth;
  var height = el.offsetHeight;
  
  bool valueInRange(int value, int min, int max){ 
    return (value >= min) && (value <= max); 
  }
  
  bool xOverlap = valueInRange(left, parent.scrollLeft, parent.scrollLeft + parent.offsetWidth) ||
                  valueInRange(parent.scrollLeft, left, left + width);

  bool yOverlap = valueInRange(top, parent.scrollTop, parent.scrollTop + parent.offsetHeight) ||
                  valueInRange(parent.scrollTop, top, top + parent.scrollHeight);

  return xOverlap && yOverlap;
}

class SelectPage {
  
  DivElement body = new DivElement();
  DivElement header = new DivElement();
  DivElement itemList = new DivElement();
  
  List<SelectPageItem> items = new List();
  List<SelectPageItem> loadQueue = new List();
  
  bool pageRequested = false;
  
  StreamController<Level> levelSelectedController = new StreamController<Level>();
  Stream<Level> get onLevelSelected => levelSelectedController.stream;
  
  
  SelectPage(){
    itemList.onScroll.listen(this.onScroll);
    
    body..append(header)
      ..append(itemList);
    
    body.style.position = 'absolute';
    body.style.top = 
        body.style.bottom = 
        body.style.right = 
        body.style.left = '0px';
    
    itemList.style.position = 'absolute';
    itemList.style.top = '50px';
    itemList.style.overflowY = 'scroll';
    itemList.style.bottom = 
      itemList.style.right = 
      itemList.style.left = '0px';
    
    
    var title = new HeadingElement.h1();
    title.innerHtml = "Choose your level";
    
    header.append(title);
    
    new Timer.periodic(new Duration(milliseconds: 10), processQueue);
  }
  
  void requestLevels(){
    if(pageRequested == true)
      return;
    
    HttpRequest.getString("microban.xsb").then((String response){
      XsbLevelPack pack = new XsbLevelPack(response);
      
      loadLevels(pack);
    });
    
    pageRequested = true;
  }
  
  void loadLevels(XsbLevelPack pack){
    
    for(XsbLevel level in pack.levels){
      addLevel(level);
    }
    
    items.take(20).forEach(loadChild);
  }
  
  void addLevel(XsbLevel level){
    SelectPageItem elem = new SelectPageItem(level);
    
    itemList.append(elem.body);
    items.add(elem);
    
    elem.body.onClick.listen((T){
      levelSelectedController.add(level.load());
    });
  }
  
  void loadChild(SelectPageItem child){
    loadQueue.add(child);
    child.isLoaded = true;
  }
  
  void onScroll(e){
    items.forEach((child){
      if(elementInViewport(child.body, itemList)){
        if(child.isLoaded == false){
          loadChild(child as SelectPageItem);
        }
      }
    });

  }
  
  void processQueue(Timer timer){
    if(loadQueue.isEmpty)
      return;
    
    SelectPageItem item = loadQueue.removeAt(0);
    item.load();    
  }
  
}

class SelectPageItem {
  XsbLevel level;
  
  DivElement body = new DivElement();
  DivElement title = new DivElement();
  CanvasElement canvas = new CanvasElement(width: XYE_HORZ * SquareSize, height: XYE_VERT * SquareSize);
  bool isLoaded = false;
  
  SelectPageItem(this.level){
    body..append(canvas)
      ..append(title);
    
    body.style.display = 'inline-block';
    body.style.margin = '8px';
    body.style.position = 'relative';
    body.style.width = '300px';
    body.style.height = '200px';
    body.style.cursor = 'pointer';
    
    title.style.position = 'absolute';
    title.style.left = title.style.right = title.style.bottom = "0px";
    title.style.height = "20px";
    title.style.backgroundColor = 'rgba(0,0,0,0.2)';
    title.style.textAlign = 'center';
    title.innerHtml = "Level #${level.id}";
   
    
    canvas.style.width = '300px';
    canvas.style.height = '200px';
  }
  
  void load(){    
    GridCanvasDrawer drawer = new GridCanvasDrawer(canvas);
    drawer.setSpriteSheet(spriteSheet, 40 );
    level.load().draw(drawer);
    print("Loaded");
  }
  
}