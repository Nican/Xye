
part of xye;

void LoadXsbWall(Point pt, {dark: false}){
  Square sq = Game.get(pt);
  Wall wall = new Wall(sq);
}

void LoadXsbMarked(Point pt, BlockColor bc){
  new Marked(Game.get(pt), bc);
}

void LoadXsbBlock(Point pt, BlockColor bc){
  new Block(Game.get(pt), bc, false);
}

void LoadXsbMarkedBlock(Point pt, BlockColor bc){
  LoadXsbMarked(pt, bc);
  LoadXsbBlock(pt, bc);
}

void SetXsbKye(Point pt){
  Game.xye.move(pt.clone());
}

void LoadXsbMarkedKye(Point pt, BlockColor bc){
  LoadXsbMarked(pt, bc);
  SetXsbKye(pt);
}

Grid<int> FromXyeDFS(Point xyePos){
  
  Grid<int> grid = new Grid(Game.grid.width, Game.grid.height);
  List<Point> directions = [Direction.UP.pt, Direction.DOWN.pt, Direction.RIGHT.pt, Direction.LEFT.pt];
  
  grid.fill(0);
  
  void DFS(Point pt, int level){
    if(grid[pt] != 0){
      return;
    }
    grid[pt] = level;
    
    directions.forEach((Point delta){
      Point newPt = new Point(pt.x + delta.x, pt.y + delta.y );
      
      if( newPt.x < 0 || newPt.y < 0 || newPt.x > grid.width || newPt.y > grid.height )
        return;
      
      Object obj = Game.get(newPt).object;
      if( obj == null || obj is Block ){
        DFS(newPt, level+1);
      }
    });
  }
  
  DFS(xyePos, 1);
  return grid;    
}

bool WhiteSpace(Point pt){
  Square sq = Game.get(pt);
  if(sq.gObject != null)
    return false;
  
  return sq.gObject == null && sq.object is! Wall;
}

bool MarkedPresentAt(Point pt){
  return Game.get(pt).gObject is Marked;
}

bool BlockedEntrance(Point pt){
  Square sq = Game.get(pt);
  return sq.gObject != null || sq.object is Wall;
}

class XsbLevel {
  
  int width;
  int height;
  
  List<List<String>> data;
  
  BlockColor color = new BlockColor("black");
  GemType gemType = new GemType("red");
  
  Point gemPosition;
  
  XsbLevel(String level){
    
    List<String> lines = level.split("\n");
    
    this.height = lines.length;
    this.width = lines.map((s)=> s.length).fold(0, max);
    
    this.data = lines.map((String line){
      while(line.length < this.width){
        line += " ";
      }
      return line.split("");
    }).toList(growable: false);
    
  }
  
  void load(){
    Point offset = new Point(
        ((XYE_HORZ- this.width)/2).toInt(),
        (XYE_VERT - ((XYE_VERT-this.height)/2)-1).toInt());
    int j, i;
    

    for (j=0;j<height;j++){
      for (i=0;i<width;i++){
        loadPoint(i, j, new Point(offset.x+i, offset.y-j));        
      }
    }
    
    Grid<int> dfs = FromXyeDFS(Game.xye.position);
    
    Game.grid.grid.forEach((Square sq){
      if(dfs[sq.position] == 0 && sq.object == null){
          new Wall(sq);
      }
    });
    FindAGoodWall(Game.xye.position);
    
    Grid<int> mem = new Grid(Game.grid.width, Game.grid.height);
    mem.fill(2);
    
    bywall = false;
    
    for (j=1;j<XYE_VERT-1;j++){
      for (i=1;i<XYE_HORZ-1;i++){
        Point pt = new Point(i,j);
        if(!WhiteSpace(pt)){
          continue;
        }
        
        if(Direction.all().any((Direction dir){
          Point newPt = pt + dir.pt; 
          return MarkedPresentAt(newPt) && !BlockedEntrance(newPt);
        })){
          EnsurePath(pt, mem, false);
        }
      
      }
    }    
  }
  
  bool bywall = false;
  
  bool EnsurePath(Point pt, Grid<int> mem, bool nowall){
    if( pt.x <= 0 || pt.y <= 0 || pt.x >= XYE_HORZ || pt.y >= XYE_VERT )
      return false;
    
    Point t = gemPosition.clone(); //TODO
    
    if (pt.x==t.x && pt.y==t.y)
      return true;
    
    int memv= mem[pt];
    if (memv < 2 )
        return memv == 0;
    if (memv > 1000) //for safety, this should never happen though
        return false;
    
    mem[pt] = 0;
    
    Square sq = Game.get(pt);
    Object object = sq.object;
    if(MarkedPresentAt(pt))
      return false;
    
    bool wallrep=false;
    
    if( object != null && object is Wall ){
      if (nowall){
        mem[pt]=memv+1;
        bywall=true;
        return false;
      }
      wallrep=true;
      object.kill();
      new BlockDoor(sq,false,true, color);
    }
    
    Point t2 = new Point(0,0);
    Point t3 = new Point(0,0);
    Point t4 = new Point(0,0);
    Point d = new Point(0,0);

    d.x=t.x-pt.x;
    d.y=t.y-pt.y;
    d.x=(d.x<0)?-d.x:d.x;
    d.y=(d.y<0)?-d.y:d.y;
    if (d.x<d.y)
    {
        t2.x=(t.x>pt.x)?pt.x+1:pt.x-1;
        t2.y=pt.y;

        t3.x=(t.x>pt.x)?pt.x-1:pt.x+1;
        t3.y=pt.y;

        t4.x=pt.x;
        t4.y=(t.y>pt.y)?pt.y-1:pt.y+1;

        t.x=pt.x;
        t.y=(t.y>pt.y)?pt.y+1:pt.y-1;
    }
    else
    {
        t2.x=pt.x;
        t2.y=(t.y>pt.y)?pt.y+1:pt.y-1;

        t3.x=pt.x;
        t3.y=(t.y>pt.y)?pt.y-1:pt.y+1;

        t4.y=pt.y;
        t4.x=(t.x>pt.x)?pt.x-1:pt.x+1;

        t.y=pt.y;
        t.x=(t.x>pt.x)?pt.x+1:pt.x-1;
    }
    
    bool wallcheck;
    if (EnsurePath(t,mem,true)){
      mem[pt]=1;
      return true;
    }
    
    wallcheck=bywall;
    
    if (EnsurePath(t2,mem,true)) {
      mem[pt]=1;
      return true;
    }
    
    wallcheck=wallcheck || bywall;

    if (EnsurePath(t3,mem,true)){
      mem[pt]=1;
      return true;
    }
    
    wallcheck=wallcheck || bywall;

    if (EnsurePath(t4,mem,true)) {
      mem[pt]=1;
      return true;
    }
    
    wallcheck=wallcheck || bywall;

    bywall=wallcheck;
    if (!nowall)
    {
        if  (EnsurePath(t,mem,false)) {
          mem[pt]=1;
          return true;
        }
        
        if  (EnsurePath(t2,mem,false)){
          mem[pt]=1;
          return true;
        }
        
        if  (EnsurePath(t3,mem,false)){
          mem[pt]=1;
          return true;
        }
        
        if  (EnsurePath(t4,mem,false)){
          mem[pt]=1;
          return true;
        }
    }
    else if (wallcheck)
        mem[pt]=memv+1;

    //else
    //    printf("??");

    /*if  (EnsurePath(tx4,ty4,mem,false,bc)) return (mem[y*XYE_HORZ+x]=1);*/


    if (wallrep)
    {
        new Wall(Game.get(pt));
    }

    return false;
    
  }
  
  
  void loadPoint(int i, int j, Point pt){
    switch(data[j][i])
    {
/*
@ - sokoban
+ - sokoban on target
# - wall
$ - box
. - target
* - box on target
*/
        case('#'): 
          LoadXsbWall(pt); 
          break;
        case('.'):
          LoadXsbMarked(pt, color); 
          break;
        case('*'):
          LoadXsbMarkedBlock(pt, color);
          break;
        case('\$'): 
          LoadXsbBlock(pt,color); 
          break;
        case('+'):
          LoadXsbMarkedKye(pt,color);
          break;
        case('@'):
          SetXsbKye(pt);
          break;
    }
  }
  
  bool FindAGoodWall(Point pt, {bool rec: true}){
    if ((pt.x==0) || (pt.y==0) || (pt.x>=XYE_HORZ) || (pt.y>=XYE_VERT))
      return false;

    Square sq = Game.get(pt);
    Object object = sq.object;
    if (object != null)
    {
      if (object is Wall)
      {
        object.kill();
        BlockDoor bd= new BlockDoor(sq, false, true, color);
        Gem gm = new Gem(sq, gemType);
        gemPosition = pt.clone();
        return true;
      }
    }
    
    if (rec)
    {
      return Direction.all().any((Direction d){
        return FindAGoodWall(pt + d.pt, rec: false);
      }) || Direction.all().any((Direction d){
        return FindAGoodWall(pt + d.pt);
      });
    }

    return false;
  }
  
}

