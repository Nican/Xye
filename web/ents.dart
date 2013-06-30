part of xye;

abstract class Ent {
  int id;
  Point get position => square.position;
  Level get level => square.level; 
  Square square;
  
  Ent(this.square){
    this.id = GameEngine.newId();
  }
  
  void move(Point pt);
  void draw(GridCanvasDrawer context);
  
  void kill();
  void onDeath();
  void updateSquare(){
    level.get(position).update = true;    
  }
  
}

abstract class GObject extends Ent {
  
  GObject(Square sq) : super(sq){
    sq.gObject = this;
    renderAfterObjects = false;
    if(sq.object != null) onEnter(sq.object);
  }
  
  bool renderAfterObjects;
  
  void onEnter(Object entering);
  void onLeave(Object entering);
  void loop();
  bool canEnter(Object entering, Direction dir);
  bool canLeave(Object entering, Direction dir);
  
  void move(Point p){
    level.get(position).gObject = null;
    level.get(position).gObject = this;
  }
  
  void kill(){
    Square sq = level.get(position);
    sq.update = true;
    sq.gObject = null;
    
    onDeath();
  }
 
}

abstract class Object extends Ent {
  
  bool killedByBlackHole = false;
  int tic = 0;
  
  Object(Square sq) : super(sq){
  
    if (sq.object != null) sq.object.kill();
    sq.object=this;
    sq.update=true;
    if (sq.gObject != null) sq.gObject.onEnter(this);
  }
  
  bool loop(KillResult result);
  bool trypush(Direction dir, Object pusher);
  
  void move(Point pt){
    Square oldSq = square;
    oldSq.update = true;
    GObject gobject = oldSq.gObject;
    
    if ( gobject != null ) 
      gobject.onLeave(this);
      
    oldSq.object= null;
    
    square = level.get(pt);
    
    if (square.object != null)
      square.object.kill();

    square.object=this;
    square.update = true;
    gobject = square.gObject;
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
      level.xye.kill();
      return;
    }
    
    this.killedByBlackHole = byBlackHole;
    this.onDeath();
    
    GObject gObject = square.gObject;
    
    if( gObject != null ){
      gObject.onLeave(this);
    }
    square.object = null;  
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
    
    Square sq = level.get(d);
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
      if (! FindMagnetic(level.get(m),rSticky,rHorz,mg, ds: true, rd: godir) )
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
        if (FindMagnetic(level.get(position.add(1,0)),true,true,mg)) return true;
        if (FindMagnetic(level.get(position.add(-1, 0)),true,true,mg)) return true;
    }
    if (vert)
    {
        if (FindMagnetic(level.get(position.add(0, 1)),true,false,mg)) return true;
        if (FindMagnetic(level.get(position.add(0, -1)),true,false,mg)) return true;
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
    
    int counter = level.counter;
    
    if( counter != deadtic )
    {
      deadtic = counter;
      if(lives > 1)
      {
        lives--;
        Point c = checkpoint.position.clone();
        Point n = new Point(0,0);
        
        if( level.getRevivePoint(c, n) ){
          move(n);
          alpha = 0;
        } else {
          lives = 0;
          level.terminateGame();
          
          Square sq = level.get(position);
          GObject gobject = sq.gObject;
          if(gobject != null) gobject.onLeave(this);
          sq.object = null;
          
          return;         
        }
        level.flashXyePosition();
      } else {
        lives = 0;
        level.terminateGame();
        
        Square sq = level.get(position);
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
      return level.TryMoveXye(dir);
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
    
    return mt == MagnetType.T_STICKY && movedTic+1>=level.counter && lastPushDir == reqdir;    
  }
  
  bool isHorizontal(){
    return horz;
  }
  
  void draw(GridCanvasDrawer context){}
  
  bool trypush(Direction dir, Object pusher){
    if(trypush_common(dir, pusher, false, null))
    {
      lastPushDir = dir;
      movedTic = level.counter;
      return true;
    }
    return false;
  }
  
  bool tryMagneticMove( Point o, Point x, Direction godir, KillResult died, {Point s} ){
    if(s == null)
      s = new Point(0,0);
    
    if(!IsXyeOrBotAt(level.get(x)))
      return false;
    
    if( mt == MagnetType.T_STICKY && level.get(x) is! Xye )
      return false;
    
    if( mt == MagnetType.T_ANTIMAGNET )
    {
      if(trypush_common(godir, this, false, died))
        return true;
      return false;
    }
    
    Square sq = level.get(o);
    if( sq.object != null ) 
      return false;
    
    if( sq.gObject != null && !sq.gObject.canEnter(this, godir) )
      return false;
    
    Point old = this.position.clone();
    move(sq.position);
    movedTic = level.counter;
    lastPushDir = godir;
    
    if( mt != MagnetType.T_STICKY )
      return true;
    
    sq = level.get(s);
    Object object = sq.object;
    
    if( object != null && object.tic != level.counter && object.affectedByMagnetism(horz))
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
            if ((mt==MagnetType.T_MAGNET || level.moved(Direction.RIGHT) ) && tryMagneticMove(position.add(1,0),position.add(2,0),Direction.RIGHT,died, s: position.add(-1, 0))) 
              return true;
            
            if ((mt==MagnetType.T_MAGNET || level.moved(Direction.LEFT) ) && (tryMagneticMove(position.add(-1,0),position.add(-2,0),Direction.LEFT,died, s: position.add(1,0)))) 
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
            if ((mt==MagnetType.T_MAGNET || level.moved(Direction.UP) ) && tryMagneticMove(position.add(0,1),position.add(0,2),Direction.UP,died, s: position.add(0,-1))) 
              return true;
            
            if ((mt==MagnetType.T_MAGNET || level.moved(Direction.DOWN) ) && tryMagneticMove(position.add(0,-1),position.add(0,-2),Direction.DOWN,died, s: position.add(0,1))) 
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
      if(anim < 3) setAnim(anim+1);
    } else if (anim > 0){
      Object obj = level.get(this.position).object;
      if(obj == null || insideKind(obj))
        setAnim(anim-1);      
    }
  }
  
  void setAnim(int val){
    square.update = true;
    anim = val;
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
  
  Wall(Square square) : super(square){
  }
  
  void onDeath(){}
  
  void draw(GridCanvasDrawer context){
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
    
    Color color = new Color(192/255,192/255,192/255);
    
    void drawCorner(bool round, bool a, bool b, bool c, RoundCorner corner){
      void drawRect(int sx, int sy){
        context.drawCorner(position, sx, sy, corner, color: color);
      }
      
      if (round)
        drawRect(10,ty);
      else if(a && b && !inborder)
        context.rect(position, color); //drawRect(15,ty);
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
    Square sq = level.get(new Point(sx,sy));
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
    /*
    context.context.beginPath();
    context.context.setLineDash([5, 2]);
    context.context.strokeStyle = 'black';
    context.context.rect(position.x * context.squareSize, position.y * context.squareSize, context.squareSize, context.squareSize);
    context.context.stroke();
    */
    context.draw(position, 6, anim+5);
    
    if (active)
      anim= (anim>=3?0:anim+1);
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
      Square sq = level.get(this.position);
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

    osq= ToMove.level.get(new Point(wx,wy));
    
    if (Allowed(ToMove,dir,osq)) 
      return osq;
    
    object=osq.object;
    if (!object) return null;
    a = object.hasRoundCorner(rca);
    if (a)
    {
        sq11=ToMove.level.get(new Point(ax1,ay1));
        sq12=ToMove.level.get(new Point(ax2,ay2));
        a= (Allowed(ToMove,adir,sq11) && Allowed(ToMove,dir,sq12) );
    }
    b = object.hasRoundCorner(rcb);
    if (b)
    {
        sq21=ToMove.level.get(new Point(bx1,by1));
        sq22=ToMove.level.get(new Point(bx2,by2));
        b= (Allowed(ToMove,bdir,sq21) && Allowed(ToMove,dir,sq22) );
    }
    
    if (a && b) {
        int x = (random.nextInt(154125)+ ToMove.level.counter+ax1*XYE_VERT+ay1)%120;
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
