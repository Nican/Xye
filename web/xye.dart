library xye;
import 'dart:html';
import 'dart:core';
import 'dart:math';
import 'dart:async';

part 'xsb.dart';
part 'ents.dart';
part 'selectpage.dart';
part 'main.dart';

final int XYE_HORZ = 30;
final int XYE_VERT = 20;
final int SquareSize = 40;

ImageElement spriteSheet = new ImageElement(src: "clean40.png");

class Color {
  double r;
  double g;
  double b;
  
  Color(this.r, this.g, this.b);
}

void main() {  
  
  window.onKeyDown.listen((KeyboardEvent e){
    GameEngine.onKeyDown(e.which);
  });
  window.onKeyUp.listen((KeyboardEvent e){
    GameEngine.onKeyUp(e.which);
  });
  
  spriteSheet.onLoad.listen((T){
    Main page = new Main();
    document.body.append(page.mainDiv);
  });
  
  
  
}

class GridCanvasDrawer {
  CanvasElement canvas;
  CanvasRenderingContext2D context; 
  
  CanvasElement spriteSheet;  
  int iconSize;  
  int get squareSize => SquareSize;  
  
  CanvasElement iconCache;
  CanvasRenderingContext2D get iconCacheContext => iconCache.getContext('2d') as CanvasRenderingContext2D;
  
  GridCanvasDrawer(this.canvas){
    context = canvas.getContext("2d") as CanvasRenderingContext2D;
  }
  
  void setSpriteSheet(ImageElement image, int squareSize){
    this.iconSize = squareSize;
    
    
    if(!image.complete){
      image.onLoad.listen((T){
        setSpriteSheet(image, squareSize);        
      });      
      return;
    }
    
    spriteSheet = new CanvasElement(width: image.width, height: image.height);
    iconCache = new CanvasElement(width: iconSize, height: iconSize); 
    
    CanvasRenderingContext2D ctx = spriteSheet.getContext('2d') as CanvasRenderingContext2D;
    ctx.drawImage(image, 0, 0);    
  }
  
  void drawCanvas(CanvasElement elem, Point position){
    context.drawImage(elem,  position.x * SquareSize,  position.y * SquareSize);
  }
  
  void clear(Point point){
    context.clearRect(point.x * iconSize, point.y * iconSize, iconSize, iconSize);
  }
  
  void _draw(num sx, num sy, num ssize, num tx, num ty, num tsize, Color color){
    
    if( color == null || color != null){
      context.drawImageScaledFromSource(
          spriteSheet, 
          sx, sy, ssize, ssize, 
          tx, ty, tsize, tsize);
      return;
    }
    
    var ctx = spriteSheet.getContext("2d") as CanvasRenderingContext2D;
    ImageData imageData = ctx.getImageData(sx, sy, ssize, ssize);
    var pixels = imageData.data;
    var numPixels = pixels.length;
    
    for (int i = 0; i < numPixels; i+=4) {
      pixels[i]   = (pixels[i]   * color.r).toInt();
      pixels[i+1] = (pixels[i+1] * color.g).toInt();
      pixels[i+2] = (pixels[i+2] * color.b).toInt();
    }
    
    iconCacheContext.putImageData(imageData, 0, 0);    
    
    context.drawImageScaledFromSource(
        iconCache, 
        0, 0, ssize, ssize, 
        tx, ty, tsize, tsize);
        
  }
  
  void drawCorner(Point point, int x, int y, RoundCorner corner, {Color color: null}){
    num sX = (corner == RoundCorner.RC_1 || corner == RoundCorner.RC_7) ? 0 : iconSize/2;
    num sY = (corner == RoundCorner.RC_7 || corner == RoundCorner.RC_9) ? 0 : iconSize/2;
    
    num dX = (corner == RoundCorner.RC_1 || corner == RoundCorner.RC_7) ? 0 : squareSize/2;
    num dY = (corner == RoundCorner.RC_7 || corner == RoundCorner.RC_9) ? 0 : squareSize/2;
    
    _draw(x * iconSize + sX, y * iconSize + sY, iconSize/2, point.x * squareSize + dX, point.y * squareSize + dY, squareSize/2, color);
  }
  
  void draw(Point point, int x, int y, {Color color: null}){
    _draw(x * iconSize, y * iconSize, iconSize, point.x * squareSize, point.y * squareSize, squareSize, color);
  }
  
  void rect(Point position, Color color){
    setColor(color);
    context.fillRect(position.x * squareSize, position.y * squareSize, squareSize, squareSize);
  }
  
  void setColor(Color color){
    context.fillStyle = "rgb(${(color.r*255).toInt()},${(color.g*255).toInt()},${(color.b*255).toInt()})";
  }
  
}

class Square {
  Object object = null;
  GObject gObject = null;
  Explosion explosion = null;
  Point position;
  bool update = true;
  bool updateLater = false;
  Level level;
  
  Square(this.position, this.level);
  
  void draw(GridCanvasDrawer drawer){
    if(update == false)
      return;
    
    update = false;
    
    drawer.clear(position);
    
    if(gObject != null && !gObject.renderAfterObjects)
      gObject.draw(drawer);
    
    if( object != null )
      object.draw(drawer);
    
    if(gObject != null && gObject.renderAfterObjects)
      gObject.draw(drawer);
  }  
  
}

class Grid<T> {
  
  int width;
  int height;
  List<T> grid;
  
  Grid(this.width, this.height){
    grid = new List(this.width * this.height);
  }
  
  int get length{
    return grid.length;
  }
  
  void fill(T value){
    grid.fillRange(0, grid.length, value);
  }
  
  T operator [](Point pt){
    return get(pt.x, pt.y);
  }
  
  void operator []=(Point pt, T value){
    grid[ pt.y * this.width + pt.x ] = value;
  }
  
  T get(int x, int y){
    return grid[ y * this.width + x ];
  }

}

class BlockColor {
  String color;
  List<Marked> marked = new List();
  

  BlockColor(this.color){
  }  
  
  int count(){
    return marked.fold(0, (int val, Marked mark){
      return mark.active ? val + 1 : val;
    });
  }
  
  void add(Marked mark){
    marked.add(mark);
  }
  
  void remove(Marked mark){
    marked.remove(mark);
  }
  
  bool atLeastOneActive(){
    return count() > 0;
  }
  
  bool allActive(){
    return count() == marked.length;
  }

  void update(Marked mark){
    
  }
}

class GemType{
  List<Gem> gems = new List();
  String color;
  
  GemType(this.color){
    
  }
  
  void add(Gem gem){
    gems.add(gem);
  }
  
  void remove(Gem gem){
    if(!gems.contains(gem))
      throw new Exception("Gem is not in the type");
    
    gems.remove(gem);
    
    if(gems.length == 0){
      //TODO: End Game
    }
  }
}

class Direction {
  final int x;
  final int y;
  
  const Direction(this.x, this.y);
  
  Point get pt{
    return new Point(x,y);
  }
  
  static const UP = const Direction(0,-1);
  static const RIGHT = const Direction(1,0);
  static const DOWN = const Direction(0,1);
  static const LEFT = const Direction(-1,0);
  
  static List<Direction> all() {
    return [UP, RIGHT, DOWN, LEFT];
  }
}

class RoundCorner {
  final int type;
  
  const RoundCorner(this.type);
  
  static const RC_1 = const RoundCorner(1);
  static const RC_7 = const RoundCorner(7);
  static const RC_9 = const RoundCorner(9);
  static const RC_3 = const RoundCorner(3);
}

typedef bool PointCondition(Square sq, Object obj);

class GameEngine {
  static int id_count = 0;
  
  static bool DK_PRESSED = false;
  static bool DK_UP_PRESSED = false;
  static bool DK_DOWN_PRESSED = false;
  static bool DK_LEFT_PRESSED = false;
  static bool DK_RIGHT_PRESSED = false;
  static int DK_PRESSED_FIRST = 0;
  static bool DK_GO = false;
  static Direction DK_DIR = Direction.DOWN;
  static Level level;
  
  
  GameEngine(){
  }  
  
  static int newId(){
    return id_count++;
  }
  

  
  static bool evalDirKeys(){
    if (DK_LEFT_PRESSED)
    {
        DK_DIR=Direction.LEFT;
        return true;
    }
    else if (DK_UP_PRESSED)
    {
        DK_DIR=Direction.UP;
        return true;
    }
    else if (DK_RIGHT_PRESSED)
    {
        DK_DIR=Direction.RIGHT;
        return true;
    }
    else if (DK_DOWN_PRESSED)
    {
        DK_DIR=Direction.DOWN;
        return true;
    }
    return false;
  }
  
  static void onKeyDown(int which){
    switch(which){
      case(38):
        DK_UP_PRESSED=DK_PRESSED=DK_GO=true; 
        DK_PRESSED_FIRST=0; 
        DK_DIR=Direction.UP; 
        break;
      case(40):
        DK_DOWN_PRESSED=DK_PRESSED=DK_GO=true; 
        DK_PRESSED_FIRST=0; 
        DK_DIR=Direction.DOWN; 
        break;
      case(37):
        DK_LEFT_PRESSED=DK_PRESSED=DK_GO=true; 
        DK_PRESSED_FIRST=0; 
        DK_DIR=Direction.LEFT; 
        break;
      case(39):
        DK_RIGHT_PRESSED=DK_PRESSED=DK_GO=true; 
        DK_PRESSED_FIRST=0; 
        DK_DIR=Direction.RIGHT; 
        break;
    }    
  }
  
  static void onKeyUp(int which){
    switch(which){
      case(38):
        DK_UP_PRESSED=false;
        if (DK_PRESSED) 
          DK_PRESSED = ((DK_DIR!=Direction.UP) || (evalDirKeys())); 
        break;
      case(40):
        DK_DOWN_PRESSED=false;
        if (DK_PRESSED) 
          DK_PRESSED = ((DK_DIR!=Direction.DOWN) || (evalDirKeys())); 
          break;
      case(37):
        DK_LEFT_PRESSED=false;
        if (DK_PRESSED) 
          DK_PRESSED = ((DK_DIR!=Direction.LEFT) || (evalDirKeys())); 
        break;
      case(39):
        DK_RIGHT_PRESSED=false;
        if (DK_PRESSED) 
          DK_PRESSED = ((DK_DIR!=Direction.RIGHT) || (evalDirKeys())); 
        break;
    }
    
  }
  
  static void moveXye(){
    if(level.gameOver)
      return;
    
    if( level.lastXyeMove + 1 < level.counter )
    {
      if( (DK_PRESSED || DK_GO) && DK_PRESSED_FIRST != 1){
        DK_GO = false;
        int fp = level.flashPos;
        
        if(level.TryMoveXye(DK_DIR))
          level.lastXyeMove = level.counter;
        else
          level.flashPos = fp;
        
      }
      
      DK_PRESSED_FIRST++;      
    }
  }
  
  static void loop(){
    if(level != null)
      level.loop();
  }
  
  static void draw(GridCanvasDrawer context){
    if(level != null)
      level.draw(context);
  }

}

class Level {
  Grid<Square> grid = new Grid(XYE_HORZ+1, XYE_VERT+1);
  Xye xye;
  int lastXyeMove = 0;
  int counter = 0;
  bool finished = false;
  bool gameOver = false;
  Direction lastXyeDir = Direction.DOWN;
  int flashPos = 0;
  
  Level(){
    for(int x = 0; x < grid.width; x++ ){
      for(int y = 0; y < grid.height; y++ ){
        var pt = new Point(x,y);
        grid[pt] = new Square( pt, this );
      }
    }
    
    startGame();
    
  }
  
  void terminate(bool good){
    
    if (good) {
      finished = true;
    }
  }
  
  void flashXyePosition(){
    //TODO
  }
  
  void startGame(){
    xye = new Xye(grid.get(0,0));
  }
  
  void draw(GridCanvasDrawer drawer)
  {
    for(Square square in grid.grid){
      square.draw(drawer);
    } 
  }
  
  Square get(Point pt){
    return grid[pt];
  }
  
  Point clamp(Point d){
    return new Point(
        (d.x >= XYE_HORZ) ? 0 : (d.x<0) ? XYE_HORZ - 1 : d.x,
        (d.y >= XYE_VERT) ? 0 : (d.y<0) ? XYE_VERT - 1 : d.y);
  }
  
  bool TryMoveXye(Direction dir){
    Point pt = xye.position.clone();
    pt.x += dir.x;
    pt.y += dir.y;
    
    return TryMoveXyeRelative(clamp(pt), dir);
  }
  
  bool TryMoveXyeRelative( Point pt, Direction dir ){
    Square sq = get(pt);
    Object object = sq.object;
    bool go = false;
    
    if( object == null ){
      go = true;
    } else {
      if((!go) && object.trypush(dir, xye))
        go=true;
    }
    
    if(go){
      xye.moved = true;
      GObject gobject = sq.gObject;
      if(gobject == null || gobject.canEnter(xye, dir))
      {
        print("Moving to {$pt}");
        xye.move(pt);
        //xye.lastdir=dir;
        lastXyeDir = dir;
        return true;
      }
    }
    
    return false;
  }
  
  bool allowedForRevive( Square sq, Object togo ){
    if( sq.object == null )
      return sq.gObject == null;
    return false;
  }
  
  bool getRevivePoint( Point c, Point n ){
    return findGoodPoint( c, n, xye, allowedForRevive );
  }
  
  bool findGoodPoint( Point c, Point r, Object togo, PointCondition cond ){
    if(cond(get(c), togo)){
      r.x = c.x;
      r.y = c.y;
      return true;
    }
    //TODO: Line 2123
    return false;
  }
  
  bool moved(Direction dir){
    return this.lastXyeMove == counter && lastXyeDir == dir;
  }
  
  void loop(){
    if(finished){
      incCounters();
    } else {
      int i =0;
      //TODO: More than one move at once / fast-forward
      loop_gameplay();
    }
  }
  
  void incCounters(){
    counter++;
  }
  
  void loopSub( Point pt ) {
    Square sq = get(pt);
    Object object = sq.object;
    bool died = false;
    KillResult result = new KillResult();
    
    if(sq.gObject != null ) sq.gObject.loop();
    
    if(object != null && object.tic != counter){
      if(object.loop(null)){ //TODO: REPORT: CRASHING ON THIS IF STATEMENT
        if(result.died == false){
          object.tic = counter;
        }
      }
    }
    
  }
  
  void loop_gameplay(){
    int i,j;
    
    incCounters();
    GameEngine.moveXye();
    
    for(j = XYE_VERT; j >= 0; j-- ){
      for(i = 0; i < XYE_HORZ; i++ ){
        loopSub(new Point(i,j));
      }
    }
    
  }
  
}


class Point {
  int x;
  int y; 
  
  Point(this.x, this.y);
  
  Point clone(){
    return new Point(x,y);
  }
  
  Point add(int dx, int dy){
    return new Point(x+dx, y+dy);
  }
  
  String toString(){
    return "Point($x,$y)";
  }
  
  Point operator +(Point other){
    return new Point(x + other.x, y + other.y);
  }
  
}



