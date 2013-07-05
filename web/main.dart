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
  DivElement header = new DivElement();
  DivElement canvasFrame = new DivElement();
  DivElement GameWonMessage = new DivElement();
  
  CanvasElement canvas = new CanvasElement(width: XYE_HORZ * SquareSize, height: XYE_VERT * SquareSize);
  CanvasRenderingContext2D get context => canvas.getContext("2d") as CanvasRenderingContext2D;
  GridCanvasDrawer drawer;
  
  Level level;
  int animationCallbackId;
  
  LevelPage(){
    drawer = new GridCanvasDrawer(canvas, spriteSheet);
    
    body.style.left = 
        body.style.right = 
        body.style.bottom = 
        body.style.top = '0px';
    body.style.position = 'absolute';
    
    header.style.left = 
        header.style.right = 
        header.style.top = '0px';
    header.style.height = '64px';
    header.style.position = 'absolute';    
    
    canvasFrame.style.left = 
        canvasFrame.style.bottom = '0px';
    canvasFrame.style.top = '64px';
    canvasFrame.style.right = '20%';
    canvasFrame.style.position = 'absolute';
    canvasFrame.style.textAlign = "center";
    canvasFrame.style.backgroundColor = "rgb(192,192,192)";
    
    canvas.style.height = '99%';    
    canvas.style.backgroundColor = 'white';
    
    body.append(header);
    body.append(canvasFrame);
    canvasFrame.append(canvas);
    
    new Timer.periodic(new Duration(milliseconds: 100), this.loop);
  }
  
  void loadLevel(Level level){
    this.level = level;
    GameEngine.level = level;
    header.innerHtml = "My level";
    cancelDraw();
    requestDraw();
  }
  
  void gameDraw(num highResTime){
    if(level == null)
      return;
    
    GameEngine.draw(drawer);
    requestDraw();
  }
  
  void requestDraw(){
    animationCallbackId = window.requestAnimationFrame(gameDraw);
  }
  
  void cancelDraw(){
    if(animationCallbackId != null)
      window.cancelAnimationFrame(animationCallbackId);
    animationCallbackId = null;
  }
  
  void loop(Timer timer){
    if(level == null)
      return;
    
    level.loop();
    
    if(level.finished){
      
    }
  }
}

