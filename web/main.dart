part of xye;



class Main {
  
  DivElement mainDiv = new DivElement();
  SelectPage page = new SelectPage();
  
  Main(){
    mainDiv.style.left = 
        mainDiv.style.right = 
        mainDiv.style.bottom = 
        mainDiv.style.top = '0px';
    mainDiv.style.position = 'absolute';
    
    loadLevelSelector();
  }
  
  void loadLevelSelector(){
    page.requestLevels();
    
    mainDiv.children.clear();
    mainDiv.append(page.body);    
  }
  
  void loadLevel(Level level){
    
    
  }
  
}

class LevelPage {
  
  DivElement body = new DivElement();
  CanvasElement canvas = new CanvasElement(width: XYE_HORZ * SquareSize, height: XYE_VERT * SquareSize);
  CanvasRenderingContext2D get context => canvas.getContext("2d") as CanvasRenderingContext2D;
  
  LevelPage(){
    
    
  }
  
  
}

void gameDraw(num highResTime){
  window.requestAnimationFrame(gameDraw);
  
  //context.clearRect(0, 0, canvas.width, canvas.height);

  //context.fillStyle = "green";
  //context.fillRect(Game.xye.position.x * SquareSize, Game.xye.position.y * SquareSize, SquareSize, SquareSize);
  
  //GameEngine.draw(context); 
}