part of xye;



class Main {
  
  DivElement mainDiv = new DivElement();
  
  SelectPage page = new SelectPage();
  LevelPage levelPage = new LevelPage();
  
  Main(){
    mainDiv.style.left = 
        mainDiv.style.right = 
        mainDiv.style.bottom = 
        mainDiv.style.top = '0px';
    mainDiv.style.position = 'absolute';
    
    loadLevelSelector();
    page.onLevelSelected.listen(loadLevel);
  }
  
  void loadLevelSelector(){
    page.requestLevels();
    
    mainDiv.children.clear();
    mainDiv.append(page.body);    
  }
  
  void loadLevel(Level level){
    levelPage.loadLevel(level);
    
    mainDiv.children.clear();
    mainDiv.append(levelPage.body);  
  }
  
}

class LevelPage {
  
  DivElement body = new DivElement();
  CanvasElement canvas = new CanvasElement(width: XYE_HORZ * SquareSize, height: XYE_VERT * SquareSize);
  CanvasRenderingContext2D get context => canvas.getContext("2d") as CanvasRenderingContext2D;
  GridCanvasDrawer drawer;
  
  Timer timer;
  
  Level level;
  
  LevelPage(){
    drawer = new GridCanvasDrawer(canvas);
    drawer.setSpriteSheet(spriteSheet, 40);
    
    body.append(canvas);
    canvas.style.width = '75%';
    canvas.style.height = '100%';
    
    new Timer.periodic(new Duration(milliseconds: 100), this.loop);
  }
  
  void loadLevel(Level level){
    this.level = level;
    GameEngine.level = level;
    requestDraw();
  }
  
  void gameDraw(num highResTime){
    if(level == null)
      return;
    
    GameEngine.draw(drawer);
    requestDraw();
  }
  
  void requestDraw(){
    window.requestAnimationFrame(gameDraw);
  }
  
  void loop(Timer timer){
    if(level == null)
      return;
    
    level.loop();
    
    if(level.finished){
      
    }
  }
}

