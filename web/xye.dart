library xye;
import 'dart:html';
import 'dart:core';
import 'dart:math';
import 'dart:async';

part 'xsb.dart';

final int XYE_HORZ = 30;
final int XYE_VERT = 20;
final int SquareSize = 40;

CanvasElement canvas = new CanvasElement(width: XYE_HORZ * SquareSize, height: XYE_VERT * SquareSize);
CanvasRenderingContext2D context = canvas.getContext("2d") as CanvasRenderingContext2D;
ImageElement spriteSheet = new ImageElement(src: "clean40.png");

String firstLevel = '''##############
#      #     #
# \$@\$\$ # . ..#
## ## ### ## #
 # #       # #
 # #   #   # #
 # ######### #
 #           #
 #############''';

class Color {
  double r;
  double g;
  double b;
  
  Color(this.r, this.g, this.b);
}

void main() {  
  document.body.append(canvas);
  
  canvas.style.width = '75%';
  canvas.style.height = '100%';
  
  window.requestAnimationFrame(gameDraw);
  window.onKeyDown.listen((KeyboardEvent e){
    Game.onKeyDown(e.which);
  });
  window.onKeyUp.listen((KeyboardEvent e){
    Game.onKeyUp(e.which);
  });
  
  HttpRequest.getString("microban.xsb").then((String response){
    new XsbLevelPack(response);
  });
  
  Timer timer = new Timer.periodic(new Duration(milliseconds: 100), (Timer t){
    Game.loop();
  });
  
  Game.startGame();
  new XsbLevel(firstLevel).load();
  
}

void gameDraw(num highResTime){
  window.requestAnimationFrame(gameDraw);
  
  context.clearRect(0, 0, canvas.width, canvas.height);

  //context.fillStyle = "green";
  //context.fillRect(Game.xye.position.x * SquareSize, Game.xye.position.y * SquareSize, SquareSize, SquareSize);
  
  Game.draw(context); 
}

bool CanPush(Object object){
  return object is Xye || object is Pusher || object is Magnetic || object is RoboXye;
}

bool IsXyeAt(Square sq)
{
    Object object= sq.object;
    if (object!= null) 
      return object is Xye;
    
    Point x = sq.position.clone();
    Point xx = Game.xye.position.clone();
    
    x.x = xx.x - x.x;
    x.y = xx.y - x.y;
    x.x=(x.x>0)?x.x:-x.x;
    x.y=(x.y>0)?x.y:-x.y;

    return (x.x==0 && x.y<=1) || (x.y==0 && x.x<=1);
}


bool IsXyeOrBotAt(Square sq)
{
    Object object = sq.object;
    if (object==null) return false;
    
    return object is Xye || object is RoboXye || object is Rattler || object is RattlerNode;
}

bool ObjectResistsFire(Object o){
  return false; //TODO: xye.cpp, Line 2186
}

class GridCanvasDrawer {
  CanvasElement canvas;
  CanvasRenderingContext2D context; 
  
  CanvasElement spriteSheet;
  int squareSize;
  
  GridCanvasDrawer(this.canvas){
    context = canvas.getContext("2d") as CanvasRenderingContext2D;
  }
  
  void setSpriteSheet(ImageElement image, int squareSize){
    this.squareSize = squareSize;
    //this.spriteSheet = image;
    if(!image.complete){
      image.onLoad.listen((T){
        setSpriteSheet(image, squareSize);        
      });      
      return;
    }
    
    int w = image.width;
    int h = image.height;
    spriteSheet = new CanvasElement(width: w, height: h);
    CanvasRenderingContext2D ctx = spriteSheet.getContext('2d') as CanvasRenderingContext2D;
    
    ctx.drawImage(image, 0, 0);    
  }
  
  void draw(Point position, int x, int y, {Color color: null}){
    /*
    context.drawImageScaledFromSource(
        this.spriteSheet, 
        x * squareSize, 
        y * squareSize, 
        squareSize, squareSize, 
        position.x * SquareSize, 
        position.y * SquareSize, 
        SquareSize, SquareSize);
        */
    
    _draw(this.canvas, x * squareSize, y * squareSize, squareSize,  position.x * SquareSize,  position.y * SquareSize, SquareSize, color);
  }
  
  void drawCanvas(CanvasElement elem, Point position){
    context.drawImage(elem,  position.x * SquareSize,  position.y * SquareSize);
  }
  
  CanvasElement newPrerenderCanvas(){
    var canvas = new CanvasElement(width: SquareSize, height: SquareSize);
    
    
    return canvas;
  }
  
  void drawCorner(CanvasElement target, int x, int y, RoundCorner corner, {Color color: null}){
    num sX = (corner == RoundCorner.RC_1 || corner == RoundCorner.RC_7) ? 0 : squareSize/2;
    num sY = (corner == RoundCorner.RC_7 || corner == RoundCorner.RC_9) ? 0 : squareSize/2;
    
    num dX = (corner == RoundCorner.RC_1 || corner == RoundCorner.RC_7) ? 0 : SquareSize/2;
    num dY = (corner == RoundCorner.RC_7 || corner == RoundCorner.RC_9) ? 0 : SquareSize/2;
    
    /*
    context.drawImageScaledFromSource(
        this.spriteSheet, 
        x * squareSize + sX, 
        y * squareSize + sY, 
        squareSize/2, squareSize/2, 
        position.x * SquareSize + dX, 
        position.y * SquareSize + dY, 
        SquareSize/2, SquareSize/2);
        */
    _draw(target, x * squareSize + sX, y * squareSize + sY, squareSize/2, dX, dY, SquareSize/2, color);
  }
  
  void _draw(CanvasElement target, num sx, num sy, num ssize, num tx, num ty, num tsize, Color color){
    if(spriteSheet == null)
      return;
    
    var ctx = spriteSheet.getContext("2d") as CanvasRenderingContext2D;
    
    ImageData imageData = ctx.getImageData(sx, sy, ssize, ssize);
    var pixels = imageData.data;
    var numPixels = pixels.length;
    
    if(color != null){
      for (var i = 0; i < numPixels/4-1; i++) {
        // set red green and blue pixels to the average value
        pixels[i*4]   = (pixels[i*4]   * color.r).toInt();
        pixels[i*4+1] = (pixels[i*4+1] * color.g).toInt();
        pixels[i*4+2] = (pixels[i*4+2] * color.b).toInt();
      }
    }
    
    CanvasRenderingContext2D context = target.getContext("2d") as CanvasRenderingContext2D;
    
    context.putImageData(imageData, tx, ty, 0, 0, tsize, tsize);    
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
  int id_count = 0;
  Grid<Square> grid = new Grid(XYE_HORZ+1, XYE_VERT+1);
  bool gameOver = false;
  int counter = 0;
  int lastXyeMove = 0;
  Direction lastXyeDir = Direction.DOWN;
  int flashPos = 0;
  Xye xye;
  
  GridCanvasDrawer drawer = new GridCanvasDrawer(canvas);
  
  bool DK_PRESSED = false;
  bool DK_UP_PRESSED = false;
  bool DK_DOWN_PRESSED = false;
  bool DK_LEFT_PRESSED = false;
  bool DK_RIGHT_PRESSED = false;
  int DK_PRESSED_FIRST = 0;
  bool DK_GO = false;
  Direction DK_DIR = Direction.DOWN;
  
  bool finishedLevel = false;
  
  GameEngine(){
    for(int x = 0; x <= XYE_HORZ; x++ ){
      for(int y = 0; y <= XYE_VERT; y++ ){
        var pt = new Point(x,y);
        grid[pt] = new Square( pt );
      }
    }
    
    drawer.setSpriteSheet(spriteSheet, 40 );
  }
  
  void startGame(){
    xye = new Xye(grid.get(0,0));
  }
  
  void draw(CanvasRenderingContext2D context)
  {
    grid.grid.forEach((Square sq){
      sq.draw(drawer);
    });  
  }
  
  int newId(){
    return id_count++;
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
    moveXye();
    
    for(j = XYE_VERT; j >= 0; j-- ){
      for(i = 0; i < XYE_HORZ; i++ ){
        loopSub(new Point(i,j));
      }
    }
    
  }
  
  bool evalDirKeys(){
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
  
  void onKeyDown(int which){
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
  
  void onKeyUp(int which){
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
  
  bool moved(Direction dir){
    return this.lastXyeMove == counter && lastXyeDir == dir;
  }
  
  void loop(){
    if(finishedLevel){
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
  
  void moveXye(){
    if(gameOver)
      return;
    
    if( lastXyeMove + 1 < counter )
    {
      if( (DK_PRESSED || DK_GO) && DK_PRESSED_FIRST != 1){
        DK_GO = false;
        int fp = flashPos;
        
        if(TryMoveXye(DK_DIR))
          lastXyeMove = counter;
        else
          flashPos = fp;
        
      }
      
      DK_PRESSED_FIRST++;      
    }
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
    
    print("Go: $go");
    
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
  
  Square get(Point pt){
    return grid[pt];
  }
  
  Point clamp(Point d){
    return new Point(
        (d.x >= XYE_HORZ) ? 0 : (d.x<0) ? XYE_HORZ - 1 : d.x,
        (d.y >= XYE_VERT) ? 0 : (d.y<0) ? XYE_VERT - 1 : d.y);
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
  
  void terminateGame(){
    //TODO
  }
  
  void flashXyePosition(){
    //TODO
  }
}

GameEngine Game = new GameEngine();

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

class Square {
  Object object = null;
  GObject gObject = null;
  Explosion explosion = null;
  Point position;
  bool update = true;
  bool updateLater = false;
  
  Square(this.position);
  
  void draw(GridCanvasDrawer context){
    
    if(gObject != null && !gObject.renderAfterObjects){
      gObject.draw(context);
    }
    
    if( object != null )
      object.draw(context);
    
    if(gObject != null && gObject.renderAfterObjects){
      gObject.draw(context);
    }
    
  }
}

abstract class Ent {
  int id;
  Point position = new Point(0,0);
  
  Ent(){
    this.id = Game.newId();
  }
  
  void move(Point pt);
  void draw(GridCanvasDrawer context);
  
  void kill();
  void onDeath();
  void updateSquare(){
    Game.get(position).update = true;    
  }
  
}

//TODO: mg is by reference
bool FindMagnetic(Square sq, bool rSticky, bool rHorz, Magnetic mg, {bool ds: false, Direction rd: Direction.DOWN})
{
    Object object = sq.object;
    
    if (object is! Magnetic ) 
      return false;
    
    mg = object as Magnetic;
    if (mg.isHorizontal( )!= rHorz) 
      return false;

    if (ds && rSticky )
        return mg.isStickyDirection(rd);

    return mg.isSticky()==rSticky;

}

class KillResult {
  bool died = false;
  
  void kill(){
    died = true;
  }
}

class MovedResult{
  bool Moved = false;
}

abstract class Object extends Ent {
  
  bool killedByBlackHole = false;
  int tic = 0;
  
  Object(Square sq){
    this.position.x = sq.position.x;
    this.position.y = sq.position.y;
    
    if (sq.object != null) sq.object.kill();
    sq.object=this;
    sq.update=true;
    if (sq.gObject != null) sq.gObject.onEnter(this);
  }
  
  
  
  bool loop(KillResult result);
  bool trypush(Direction dir, Object pusher);
  
  void move(Point pt){
    Square sq = Game.get(this.position);
    sq.update = true;
    GObject gobject = sq.gObject;
    
    if ( gobject != null ) 
      gobject.onLeave(this);
      
    sq.object= null;
    this.position.x = pt.x;
    this.position.y = pt.y;
    
    sq = Game.get(this.position);
    sq.update=true; //Make sure to update it
    
    Object object=sq.object;
    if (object != null)
      object.kill();

    gobject = sq.gObject;
    sq.object=this;
    if (gobject != null) 
      gobject.onEnter(this);
    
  }
  
  bool hasRoundCorner(RoundCorner corner){
    return false;
  }
  
  bool hasBlockColor(BlockColor bc){
    return false;
  }
  
  void kill({bool byBlackHole: false}){
    updateSquare();
    
    if( this is Xye ){
      Game.xye.kill();
      return;
    }
    
    this.killedByBlackHole = byBlackHole;
    this.onDeath();
    
    Square sq = Game.get(position);
    GObject gObject = sq.gObject;
    
    if( gObject != null ){
      gObject.onLeave(this);
    }
    sq.object = null;  
  }
  
  bool trypush_common( Direction dir, Object pusher, bool isRound, KillResult died ){
    
    if( pusher != null && pusher != this && !CanPush(pusher)){
      return false; 
    }
    
    if(isRound){
      Square sq = RoundAdvance(this, dir, this.position);
      if(sq != null ){
        move(sq.position);
        return true;
      }
    }
    
    Point d = new Point(
        (dir.x + this.position.x).clamp(0, XYE_HORZ - 1),
        (dir.y + this.position.y).clamp(0, XYE_VERT - 1));
    
    Square sq = Game.get(d);
    Object inobj = sq.object;
    Dangerous blck;
    
    if( inobj != null){
      /*
      if( inobj is Teleport ){
        Teleport tele = inobj as Teleport;
        Point n = new Point(0,0);
        
        //TODO: blck by reference
        if( tele.tryTeleport(dir, this, n, blck, null)){
          sq = Game.get(n);
          inobj = sq.object;
        } else if( blck != null ){
          if( blck.busy(this)) return false;
          
          died.kill();
          blck.eat();
          this.kill(blck is BlackHole);
          
          return true;
        }
        
      } else if ( inobj is BlackHole || inobj is Mine || ObjectResistsFire(this)){
        blck = inobj as Dangerous;
        if( blck.busy(this) )
          return false;

        if( inobj is Mine && ObjectResistsFire(this) ){
          blck.kill();
          Game.smallBoom( Game.get(d), false, d.x - this.x, d.y - this.y );
          inobj = null;
        } else {
          //Kill the object
          died.kill();
          blck.eat();
          this.kill(blck is BlackHole);
          return true;          
        }
      }
      */
    }
    
    if( inobj == null && (sq.gObject == null || sq.gObject.canEnter(this,dir) ))
    {
      move(d);
      return true;      
    }
    
    return false;
  }  

  bool magnetism(Point o, Point m, bool rSticky, bool rHorz, Direction godir)
  {
      Magnetic mg;
      if (! FindMagnetic(Game.get(m),rSticky,rHorz,mg, ds: true, rd: godir) )
          return false; //Square didn't have the magnetic we want.
  
      //We have found a valid magnetic block, let's see if it is possible to move the object to
      // the desired point.
  
      return trypush(godir,mg);
  }
  
  bool doMagnetism(bool horz, bool vert, MovedResult moved)
  {
    moved.Moved = true;
    if (horz)
    {
        // #->][
        if (magnetism(position.add(1, 0), position.add(2, 0),true,true, Direction.RIGHT)) return true;

        // ][<-#
        if (magnetism(position.add(-1, 0), position.add(-2, 0),true,true, Direction.LEFT)) return true;

        // <-#][
        if (magnetism(position.add(-1, 0), position.add(1, 0),false,true, Direction.LEFT)) return true;

        // ][#->
        if (magnetism(position.add(1, 0), position.add(-1, 0),false,true, Direction.RIGHT)) return true;
    }

    if (vert)
    {
        // ][
        // /\
        // #
        if (magnetism(position.add(0, 1), position.add(0, 2),true,false, Direction.UP)) return true;

        // #
        // \/
        // ][
        if (magnetism(position.add(0, -1), position.add(0, -2),true,false, Direction.DOWN)) return true;

        // /\
        // #
        // ][
        if (magnetism(position.add(0, 1), position.add(0, -1),false,false, Direction.UP)) return true;

        // ][
        // #
        // \/
        if (magnetism(position.add(0, -1), position.add(0, 1),false,false, Direction.DOWN)) return true;

    }

    //Now check if a sticky magnetic is holding our object:
    Magnetic mg;
    moved.Moved = false;
    if (horz)
    {
        if (FindMagnetic(Game.get(position.add(1,0)),true,true,mg)) return true;
        if (FindMagnetic(Game.get(position.add(-1, 0)),true,true,mg)) return true;
    }
    if (vert)
    {
        if (FindMagnetic(Game.get(position.add(0, 1)),true,false,mg)) return true;
        if (FindMagnetic(Game.get(position.add(0, -1)),true,false,mg)) return true;
    }


    return false;
  }
  
  bool affectedByMagnetism(bool horz){
    //TODO: xye.cpp, line 2950
    if( this is Xye )
      return true;
    
    return false;
  }
  
}


class Xye extends Object {
  int lives = 4;
  Square checkpoint;
  bool moved = false;
  int alpha;
  int deadtic;
  Color color = new Color(52/255, 255/255, 52/255);
  
  Xye(Square sq) : super(sq) {
    this.checkpoint = sq;
    alpha = 255;
  }
  
  void onDeath(){
    throw new Exception("Xye should not die this way");
  }
  
  void draw(GridCanvasDrawer context){
    context.draw(position, 0, 0, color: color);
  }
  
  void kill({bool byBlackHole: false}){
    if( lives == 0 )
      return;
    
    int counter = Game.counter;
    
    if( counter != deadtic )
    {
      deadtic = counter;
      if(lives > 1)
      {
        lives--;
        Point c = checkpoint.position.clone();
        Point n = new Point(0,0);
        
        if( Game.getRevivePoint(c, n) ){
          move(n);
          alpha = 0;
        } else {
          lives = 0;
          Game.terminateGame();
          
          Square sq = Game.get(position);
          GObject gobject = sq.gObject;
          if(gobject != null) gobject.onLeave(this);
          sq.object = null;
          
          return;         
        }
        Game.flashXyePosition();
      } else {
        lives = 0;
        Game.terminateGame();
        
        Square sq = Game.get(position);
        GObject gobject = sq.gObject;
        if(gobject != null) gobject.onLeave(this);
        sq.object = null;
      }
    }
    
  }
  
  bool loop(KillResult result){
    return true;    
  }
  
  bool trypush(Direction dir, Object pusher){
    if( pusher is RoboXye )
      return Game.TryMoveXye(dir);
    return false;
  }
}

class MagnetType {
  final int type;
  
  const MagnetType(this.type);
  
  static const T_MAGNET = const MagnetType(0);
  static const T_ANTIMAGNET = const MagnetType(1);
  static const T_STICKY = const MagnetType(2);
}

class Magnetic extends Object {
  
  MagnetType mt;
  bool horz;
  Direction lastPushDir;
  int movedTic;
  
  Magnetic(Square sq, this.mt, this.horz ) : super(sq) {
    lastPushDir = Direction.DOWN;
    movedTic = 0;
  }
  
  bool isSticky(){
    return mt == MagnetType.T_MAGNET || mt == MagnetType.T_STICKY;
  }
  
  bool isStickyDirection(Direction reqdir){
    if(mt == MagnetType.T_MAGNET) 
      return true;
    
    return mt == MagnetType.T_STICKY && movedTic+1>=Game.counter && lastPushDir == reqdir;    
  }
  
  bool isHorizontal(){
    return horz;
  }
  
  void draw(GridCanvasDrawer context){}
  
  bool trypush(Direction dir, Object pusher){
    if(trypush_common(dir, pusher, false, null))
    {
      lastPushDir = dir;
      movedTic = Game.counter;
      return true;
    }
    return false;
  }
  
  bool tryMagneticMove( Point o, Point x, Direction godir, KillResult died, {Point s} ){
    if(s == null)
      s = new Point(0,0);
    
    if(!IsXyeOrBotAt(Game.get(x)))
      return false;
    
    if( mt == MagnetType.T_STICKY && !IsXyeAt(Game.get(x)) )
      return false;
    
    if( mt == MagnetType.T_ANTIMAGNET )
    {
      if(trypush_common(godir, this, false, died))
        return true;
      return false;
    }
    
    Square sq = Game.get(o);
    if( sq.object != null ) 
      return false;
    
    if( sq.gObject != null && !sq.gObject.canEnter(this, godir) )
      return false;
    
    Point old = this.position.clone();
    move(sq.position);
    movedTic = Game.counter;
    lastPushDir = godir;
    
    if( mt != MagnetType.T_STICKY )
      return true;
    
    sq = Game.get(s);
    Object object = sq.object;
    
    if( object != null && object.tic != Game.counter && object.affectedByMagnetism(horz))
      object.trypush(godir, this);
    
    return true;    
  }
  
  bool loop(KillResult died){
    
    if( horz ){
      if(mt != MagnetType.T_ANTIMAGNET ){
        
      }
    }
    
    if (horz)
    {
        if (mt!=MagnetType.T_ANTIMAGNET)
        {
            if ((mt==MagnetType.T_MAGNET || Game.moved(Direction.RIGHT) ) && tryMagneticMove(position.add(1,0),position.add(2,0),Direction.RIGHT,died, s: position.add(-1, 0))) 
              return true;
            
            if ((mt==MagnetType.T_MAGNET || Game.moved(Direction.LEFT) ) && (tryMagneticMove(position.add(-1,0),position.add(-2,0),Direction.LEFT,died, s: position.add(1,0)))) 
              return true;
        }
        else
        {
            if (tryMagneticMove(position.add(1,0),position.add(-1,0),Direction.RIGHT,died)) 
              return true;
            if (tryMagneticMove(position.add(-1,0),position.add(1,0),Direction.LEFT,died)) 
              return true;
        }
    }
    else
    {
        if (mt!=MagnetType.T_ANTIMAGNET)
        {
            if ((mt==MagnetType.T_MAGNET || Game.moved(Direction.UP) ) && tryMagneticMove(position.add(0,1),position.add(0,2),Direction.UP,died, s: position.add(0,-1))) 
              return true;
            
            if ((mt==MagnetType.T_MAGNET || Game.moved(Direction.DOWN) ) && tryMagneticMove(position.add(0,-1),position.add(0,-2),Direction.DOWN,died, s: position.add(0,1))) 
              return true;
        }
        else
        {
            if (tryMagneticMove(position.add(0,1),position.add(0,-1),Direction.UP,died)) 
              return true;
            if (tryMagneticMove(position.add(0,-1),position.add(0,1),Direction.DOWN,died)) 
              return true;
        }
    }
    
    MovedResult result = new MovedResult();
    if (doMagnetism(!horz, horz, result)) 
      return result.Moved;
    return false;
    
  }
  
  void onDeath(){
    
  }
  
  
}

class BlockDoor extends GObject {
  BlockColor color;
  bool mode;
  bool trap;
  int anim = 0;
  
  BlockDoor(Square sq, this.trap, this.mode, this.color ) : super(sq){
    
  }
  
  void loop(){
    if(isOpen()){
      if(anim < 3) anim++;
    } else if (anim > 0){
      Object obj = Game.get(this.position).object;
      if(obj == null || insideKind(obj))
        anim--;      
    }
  }
  
  void draw(GridCanvasDrawer context){
    context.draw(position, 7, 5+anim);
    //context.drawImageScaledFromSource(spriteSheet, 7*40, (5+anim)*40, 40, 40, position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
  }
  
  void onDeath(){
    
  }
  
  void onEnter(Object entering){
    if(!isOpen() && insideKind(entering))
      renderAfterObjects = true;
  }
  
  void onLeave(Object entering){
    renderAfterObjects = false;
  }
  
  bool canEnter(Object entering, Direction dir){
    return isOpen();
  }
  
  bool canLeave(Object entering, Direction dir){
    return true;
  }
  
  bool isOfColor(BlockColor bc){
    return bc == color;
  }
  
  bool isOpen(){
    if(trap)
      return color.atLeastOneActive() == mode;
    return color.allActive() == mode;
  }
  
  bool insideKind(Object obj){
    return obj is Gem || obj is Key || obj is Earth;
  }
  
}

class Wall extends Object {
  
  bool round7 = false;
  bool round1 = false;
  bool round3 = false;
  bool round9 = false;
  int kind = 0;
  
  CanvasElement prerenderCanvas;
  
  Wall(Square square) : super(square){
  }
  
  void onDeath(){}
  
  void updateCanvas(GridCanvasDrawer context){
    
    int sz2 = (SquareSize/2).toInt();
    int ty = kind;
    
    int px= position.x, py=position.y;
    int rx=px+1, lx=px-1, uy=py+1, dy=py-1;
    if(rx>=XYE_HORZ) rx=0;
    if(uy>=XYE_VERT) uy=0;
    if(lx<0) lx=XYE_HORZ-1;
    if(dy<0) dy=XYE_VERT-1;
    
    bool up =   find( px, uy, kind) != null;
    bool down = find( px, dy, kind) != null;
    bool left = find( lx, py, kind) != null;
    bool right = find( rx, py, kind) != null;

    bool upright = find(rx,uy,kind) != null;
    bool downright =find(rx,dy,kind) != null;
    bool upleft = find(lx,uy,kind) != null;
    bool downleft = find(lx,dy,kind) != null;
    
    up = up && !round7 && !round9;
    down = down && !round1 && !round3;
    right = right && !round9 && !round3;
    left = left && !round7 && !round1;
    
    bool inborder = !left||!up||!right||!down;
    if( !inborder && (!upright || !upleft || !downright ||!downleft) )
        inborder=true;
    
    prerenderCanvas = context.newPrerenderCanvas();
    Color color = new Color(192/255,192/255,192/255);
    
    void drawCorner(bool round, bool a, bool b, bool c, RoundCorner corner){
      void drawRect(int sx, int sy){
        context.drawCorner(prerenderCanvas, sx, sy, corner, color: color);
      }
      
      if (round)
        drawRect(10,ty);
      else if(a && b && !inborder)
        drawRect(15,ty);
      else if(a && b && c )
        drawRect(14,ty);
      else if(a && b)
        drawRect(13,ty);
      else if (a)
        drawRect(12,ty);
      else if (b)
        drawRect(11,ty);
      else
        drawRect(9,ty);
    }
    
    drawCorner(round7, up, left, upleft, RoundCorner.RC_7);
    drawCorner(round9, up, right, upright, RoundCorner.RC_9);
    drawCorner(round1, down, left, downleft, RoundCorner.RC_1);
    drawCorner(round3, down, right, downright, RoundCorner.RC_3);
  }
  
  void draw(GridCanvasDrawer context){
    if(prerenderCanvas == null)
      updateCanvas(context);
    
    context.drawCanvas(prerenderCanvas, position);
 
    //context.context.fillStyle = "black";
    //context.context.fillRect(position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
    
  }
  
  bool containsRoundCorner()
  {
    return round1 || round7 || round9 || round3;
  }
  
  bool loop(KillResult result){
    return true;
  }
  
  bool hasRoundCorner(RoundCorner corner){
    switch(corner){
      case RoundCorner.RC_1: 
        return round1;
      case RoundCorner.RC_3: 
        return round3;
      case RoundCorner.RC_7: 
        return round7;
      case RoundCorner.RC_9: 
        return round9;
    }
    throw new Exception("Unkown corner");
  }
  
  Wall find(int sx, int sy, int kind ){
    Square sq = Game.get(new Point(sx,sy));
    if( sq.object != null && sq.object is Wall){
      Wall other = sq.object as Wall;
      if(kind == 6 || other.kind == 6 || other.kind == kind)
        return other;
    }
    return null;
  }
  
  bool trypush(Direction dir, Object pusher){
    return false;
  }
  
}

class Marked extends GObject {
  
  BlockColor bc;
  int anim = 0;
  bool active = false;
  
  Marked(Square sq, this.bc) : super(sq){
    bc.add(this);
  }
  
  void onDeath(){
    bc.remove(this);
  }
  
  void draw(GridCanvasDrawer context){
    context.context.beginPath();
    context.context.setLineDash([5, 2]);
    context.context.strokeStyle = 'black';
    context.context.rect(position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
    context.context.stroke();
  }
  
  void onEnter(Object entering){
    active = renderAfterObjects = entering.hasBlockColor(bc);  
    bc.update(this);
  }
  
  void onLeave(Object entering){
    active = renderAfterObjects = false;
    bc.update(this);
  }
  
  void loop(){
    
  }
  
  bool canEnter(Object entering, Direction dir){
    return true;
  }
  
  bool canLeave(Object entering, Direction dir){
    return true;
  }
  
}

class Block extends Object {
  
  BlockColor color;
  bool round;
  bool colorless = false;
  
  Block(Square sq, this.color, this.round) : super(sq){
    
  }
  
  void onDeath(){
    
  }
  
  void draw(GridCanvasDrawer context){
    //context.fillStyle = "blue";
    //context.fillRect(position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
    
    if(round){
      //context.drawImageScaledFromSource(spriteSheet, 2*40, 0*40, 40, 40, position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
      context.draw(position, 2, 0);
    } else {
      //context.drawImageScaledFromSource(spriteSheet, 1*40, 0*40, 40, 40, position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
      context.draw(position, 1, 0);
    }
  }
  
  bool trypush(Direction dir, Object pusher){
    KillResult result = new KillResult();
    return trypush_common(dir, pusher, round, result);
  }
  
  bool hasRoundCorner(RoundCorner corner){
    return round;
  }
  
  bool loop(KillResult result){
    MovedResult moved = new MovedResult();
    if(doMagnetism(true, true, moved)){
      return moved.Moved;
    }
    
    return false;    
  }
  
  bool hasBlockColor(BlockColor color){
    return !colorless && this.color == color;
  }
  
}

class Gem extends Object {
  bool anim;
  GemType gemkind;
  
  Gem(Square square, this.gemkind ) : super(square){
    gemkind.add(this);
  }
  
  bool loop(KillResult result){
    return false;
  }
  
  void draw(GridCanvasDrawer context){
    context.draw(position, 5, 3);
    //context.drawImageScaledFromSource(spriteSheet, 5*40, 3*40, 40, 40, position.x * SquareSize, position.y * SquareSize, SquareSize, SquareSize);
  }
  
  void onDeath(){
    
  }
  
  bool trypush(Direction dir, Object pusher){
    
    if( pusher is Xye ){
      Square sq = Game.get(this.position);
      GObject gobject = sq.gObject;
      if( gobject != null && !gobject.canEnter(pusher, dir))
          return false;
      
      sq.object = null;
      gemkind.remove(this);
      return true;      
    }
    return false;    
  }
  
  
  
}

class Dangerous extends Object {
  
}

class Explosion {
  
}

class Teleport extends Object {
  
}

class Key extends Object {
  
}

class Earth extends Object {
  
}

class RattlerNode {
  
}

class Pusher {
  
}

class Rattler {
  
}

class RoboXye {
  
}

class BlackHole {
  
}

abstract class GObject extends Ent {
  
  GObject(Square sq){
    position = sq.position.clone();
    sq.gObject = this;
    renderAfterObjects = false;
    if(sq.object != null) onEnter(sq.object);
  }
  
  bool renderAfterObjects;
  
  void draw(GridCanvasDrawer context);
  void onEnter(Object entering);
  void onLeave(Object entering);
  void loop();
  bool canEnter(Object entering, Direction dir);
  bool canLeave(Object entering, Direction dir);
  
  void move(Point p){
    Game.get(position).gObject = null;
    position = p;
    Game.get(position).gObject = this;
  }
  
  void kill(){
    Square sq = Game.get(position);
    sq.update = true;
    sq.gObject = null;
    
    onDeath();
  }
 
}

bool Allowed(Object object, Direction dir, Square sq)
{
    if (sq.object== null)
    {
        GObject gobject=sq.gObject;
        return ((gobject==null) || (gobject.canEnter(object,dir)));
    }
    return false;
}

Square RoundAvance_Sub(Object ToMove,
     Direction dir, int wx, int wy,
     RoundCorner rca, Direction adir, int ax1, int ay1, int ax2, int ay2,
     RoundCorner rcb, Direction bdir, int bx1, int by1, int bx2, int by2)
{
    //HGE* hge=game::hge;
    Square osq;
    Object object;
    GObject gobject;
    Square sq11,sq12, sq21, sq22;
    Random random = new Random();
    bool a,b;

    osq=Game.get(new Point(wx,wy));
    
    if (Allowed(ToMove,dir,osq)) 
      return osq;
    
    object=osq.object;
    if (!object) return null;
    a = object.hasRoundCorner(rca);
    if (a)
    {
        sq11=Game.get(new Point(ax1,ay1));
        sq12=Game.get(new Point(ax2,ay2));
        a= (Allowed(ToMove,adir,sq11) && Allowed(ToMove,dir,sq12) );
    }
    b = object.hasRoundCorner(rcb);
    if (b)
    {
        sq21=Game.get(new Point(bx1,by1));
        sq22=Game.get(new Point(bx2,by2));
        b= (Allowed(ToMove,bdir,sq21) && Allowed(ToMove,dir,sq22) );
    }
    
    if (a && b) {
        int x = (random.nextInt(154125)+ Game.counter+ax1*XYE_VERT+ay1)%120;
        if  ( x<60 ) {
            return sq12;
        } else {
            return sq22;
        }
    } else if (a) {
        return sq12;
    } else if (b) {
        return sq22;
    }
    return null;
}

Square RoundAdvance(Object ToMove, Direction dir, Point pt)
{

    //HGE* hge=game::hge;
    Square osq;
    Object object;
    GObject gobject;

    Square sq11,sq12, sq21, sq22;

    bool a=false,b=false;
    int i = pt.x;
    int j = pt.y;
    
    switch(dir)
    {
          //RoundAvance_Sub does all the checks for us
        case(Direction.UP): return
             RoundAvance_Sub(ToMove,Direction.UP,i,j+1,
                             RoundCorner.RC_1,Direction.LEFT,i-1,j,i-1,j+1,
                             RoundCorner.RC_3,Direction.RIGHT,i+1,j,i+1,j+1);

        case(Direction.DOWN): return
             RoundAvance_Sub(ToMove,Direction.DOWN,i,j-1,
                             RoundCorner.RC_7,Direction.LEFT,i-1,j,i-1,j-1,
                             RoundCorner.RC_9,Direction.RIGHT,i+1,j,i+1,j-1);

        case(Direction.LEFT): return
             RoundAvance_Sub(ToMove,Direction.LEFT,i-1,j,
                             RoundCorner.RC_9,Direction.UP  ,i  ,j+1,i-1,j+1,
                             RoundCorner.RC_3,Direction.DOWN,i  ,j-1,i-1,j-1);

    }
      /*D_RIGHT*/     return
             RoundAvance_Sub(ToMove,Direction.RIGHT,i+1,j,
                             RoundCorner.RC_7,Direction.UP  ,i  ,j+1,i+1,j+1,
                             RoundCorner.RC_1,Direction.DOWN,i  ,j-1,i+1,j-1);
}

