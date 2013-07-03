part of xye;

class Color {
  double r;
  double g;
  double b;
  
  Color(this.r, this.g, this.b);
  
  operator ==(Color other) => this.r == other.r && this.g == other.g && this.b == other.b;
}

class GridCanvasDrawer {
  CanvasElement canvas;
  CanvasRenderingContext2D context; 
  
  SpriteSheet spriteSheet;  
  num iconSize;
  num squareSize;  
  
  GridCanvasDrawer(this.canvas, this.spriteSheet){
    context = canvas.getContext("2d") as CanvasRenderingContext2D;   
    squareSize = canvas.width / XYE_HORZ;
    iconSize = spriteSheet.iconSize; 
  }

  void drawCanvas(CanvasElement elem, Point position){
    context.drawImage(elem,  position.x * SquareSize,  position.y * SquareSize);
  }
  
  void clear(Point point){
    context.clearRect(point.x * iconSize, point.y * iconSize, iconSize, iconSize);
  }
  
  void drawCorner(Point point, num x, num y, RoundCorner corner, {Color color: null}){
    num sX = (corner == RoundCorner.RC_1 || corner == RoundCorner.RC_7) ? 0 : iconSize/2;
    num sY = (corner == RoundCorner.RC_7 || corner == RoundCorner.RC_9) ? 0 : iconSize/2;
    
    num dX = (corner == RoundCorner.RC_1 || corner == RoundCorner.RC_7) ? 0 : squareSize/2;
    num dY = (corner == RoundCorner.RC_7 || corner == RoundCorner.RC_9) ? 0 : squareSize/2;
    
    dX += point.x * squareSize;
    dY += point.y * squareSize;
    
    if(color == null){
      context.drawImageScaledFromSource(
          spriteSheet.canvas, 
          x * iconSize + sX, y * iconSize + sY, iconSize, iconSize, 
          dX, dY, squareSize, squareSize);
      return;
    }
    
    CanvasElement icon = spriteSheet.getIcon(x, y, color);
    context.drawImageScaledFromSource(
        icon,
        sX, sY, iconSize/2, iconSize/2, 
        dX, dY, squareSize/2, squareSize/2);
  }
  
  void draw(Point point, num x, num y, {Color color: null}){
    if(color == null){
      context.drawImageScaledFromSource(
          spriteSheet.canvas, 
          x * iconSize, y * iconSize, iconSize, iconSize, 
          point.x * squareSize, point.y * squareSize, squareSize, squareSize);
      return;
    }
    
    CanvasElement icon = spriteSheet.getIcon(x, y, color);
    context.drawImageScaled(
        icon,
        point.x * squareSize, point.y * squareSize, squareSize, squareSize);
    
  }
  
  void rect(Point position, Color color){
    setColor(color);
    context.fillRect(position.x * squareSize, position.y * squareSize, squareSize, squareSize);
  }
  
  void setColor(Color color){
    context.fillStyle = "rgb(${(color.r*255).toInt()},${(color.g*255).toInt()},${(color.b*255).toInt()})";
  }
  
}

class SpriteSheet {
  CanvasElement canvas;
  CanvasRenderingContext2D get context => canvas.getContext("2d") as CanvasRenderingContext2D;
  int iconSize;
  
  List<SpriteSheetIcon> iconCache = [];
  
  SpriteSheet(this.canvas, this.iconSize){
    
  }
  
  CanvasElement getIcon(num x, num y, Color color){
    for(SpriteSheetIcon icon in iconCache ){
      if(icon.color == color && icon.x == x && icon.y == y)
        return icon.canvas;
    }
    
    CanvasElement canvas = new CanvasElement(width: iconSize, height: iconSize);
    ImageData imageData = context.getImageData(x * iconSize, y * iconSize, iconSize, iconSize);
    var pixels = imageData.data;
    var numPixels = pixels.length;
    
    if( color != null ){
      for (int i = 0; i < numPixels; i+=4) {
        pixels[i]   = (pixels[i]   * color.r).toInt();
        pixels[i+1] = (pixels[i+1] * color.g).toInt();
        pixels[i+2] = (pixels[i+2] * color.b).toInt();
      }
    }
    
    print("New icon $x $y ${color.r}");
    
    SpriteSheetIcon icon = new SpriteSheetIcon(canvas, x, y, color);
    icon.context.putImageData(imageData, 0, 0);    
    
    iconCache.add(icon);
    
    return icon.canvas;    
  }

}

class SpriteSheetIcon {
  
  Color color;
  CanvasElement canvas;
  num x;
  num y;
  
  CanvasRenderingContext2D get context => canvas.getContext("2d") as CanvasRenderingContext2D;
  
  SpriteSheetIcon(this.canvas, this.x, this.y, this.color);
  
  operator ==(SpriteSheetIcon other) => this.color == other.color && this.x == other.x && this.y == other.y;

}