
part of xye;

class XsbLevelPack {
  
  List<XsbLevel> levels = new List();
  
  XsbLevelPack(String levelsData){
    int id = 1;
    
    levelsData.split(";").forEach((item){
      List<String> lines = item.split("\n");
      lines.removeAt(0);
      lines.removeAt(0);
      
      if(lines.length < 3)
        return;
      
      levels.add(new XsbLevel(id, lines.join("\n")));      
      id++;
    });    
    
    print("Loaded ${levels.length} levels");
  }
  
}

void LoadXsbWall(Level level, Point pt, {dark: false}){
  Square sq = level.get(pt);
  Wall wall = new Wall(sq);
}

void LoadXsbMarked(Level level, Point pt, BlockColor bc){
  new Marked(level.get(pt), bc);
}

void LoadXsbBlock(Level level, Point pt, BlockColor bc){
  new Block(level.get(pt), bc, false);
}

void LoadXsbMarkedBlock(Level level, Point pt, BlockColor bc){
  LoadXsbMarked(level,pt, bc);
  LoadXsbBlock(level,pt, bc);
}

void SetXsbKye(Level level, Point pt){
  level.xye.move(pt.clone());
}

void LoadXsbMarkedKye(Level level, Point pt, BlockColor bc){
  LoadXsbMarked(level, pt, bc);
  SetXsbKye(level, pt);
}

Grid<int> FromXyeDFS(Level level, Point xyePos){
  
  Grid<int> grid = new Grid(level.grid.width, level.grid.height);
  List<Point> directions = [Direction.UP.pt, Direction.DOWN.pt, Direction.RIGHT.pt, Direction.LEFT.pt];
  
  grid.fill(0);
  
  void DFS(Point pt, int depth){
    if(grid[pt] != 0){
      return;
    }
    grid[pt] = depth;
    
    directions.forEach((Point delta){
      Point newPt = new Point(pt.x + delta.x, pt.y + delta.y );
      
      if( newPt.x < 0 || newPt.y < 0 || newPt.x > grid.width || newPt.y > grid.height )
        return;
      
      Object obj = level.get(newPt).object;
      if( obj == null || obj is Block ){
        DFS(newPt, depth+1);
      }
    });
  }
  
  DFS(xyePos, 1);
  return grid;    
}

bool WhiteSpace(Square sq){
  if(sq.gObject != null)
    return false;
  
  return sq.gObject == null && sq.object is! Wall;
}

class XsbLevel {
  
  int id;
  int width;
  int height;
  
  List<List<String>> data;
  Point gemPosition;
  
  BlockColor color;
  GemType gemType;
  
  XsbLevel(this.id, String level){
    
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
  
  Level load(){
    Point offset = new Point(
        ((XYE_HORZ- this.width)/2).toInt(),
        (XYE_VERT - ((XYE_VERT-this.height)/2)-1).toInt());
    int j, i;
    Level level = new Level();
    
    color = new BlockColor("black");
    gemType = new GemType("red");

    for (j=0;j<height;j++){
      for (i=0;i<width;i++){
        loadPoint(level, i, j, new Point(offset.x+i, offset.y-j));        
      }
    }
    
    Grid<int> dfs = FromXyeDFS(level, level.xye.position);
    
    level.grid.grid.forEach((Square sq){
      if(dfs[sq.position] == 0 && sq.object == null){
          new Wall(sq);
      }
    });
    FindAGoodWall(level, level.xye.position);
    
    Grid<int> mem = new Grid(level.grid.width, level.grid.height);
    mem.fill(2);
    
    bywall = false;
    
    for (j=1;j<XYE_VERT-1;j++){
      for (i=1;i<XYE_HORZ-1;i++){
        Point pt = new Point(i,j);
        if(!WhiteSpace(level.get(pt))){
          continue;
        }
        
        if(Direction.all().any((Direction dir){
          Square sq = level.get(pt + dir.pt);
          return sq.gObject is Marked && sq.object is! Wall;
        })){
          EnsurePath(level, pt, mem, false);
        }
      
      }
    } 
    
    return level;
  }
  
  bool bywall = false;
  
  bool EnsurePath(Level level, Point pt, Grid<int> mem, bool nowall){
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
    
    Square sq = level.get(pt);
    Object object = sq.object;
    if(sq.gObject is Marked)
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
    if (EnsurePath(level, t,mem,true)){
      mem[pt]=1;
      return true;
    }
    
    wallcheck=bywall;
    
    if (EnsurePath(level,t2,mem,true)) {
      mem[pt]=1;
      return true;
    }
    
    wallcheck=wallcheck || bywall;

    if (EnsurePath(level,t3,mem,true)){
      mem[pt]=1;
      return true;
    }
    
    wallcheck=wallcheck || bywall;

    if (EnsurePath(level,t4,mem,true)) {
      mem[pt]=1;
      return true;
    }
    
    wallcheck=wallcheck || bywall;

    bywall=wallcheck;
    if (!nowall)
    {
        if  (EnsurePath(level,t,mem,false)) {
          mem[pt]=1;
          return true;
        }
        
        if  (EnsurePath(level,t2,mem,false)){
          mem[pt]=1;
          return true;
        }
        
        if  (EnsurePath(level,t3,mem,false)){
          mem[pt]=1;
          return true;
        }
        
        if  (EnsurePath(level,t4,mem,false)){
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
        new Wall(level.get(pt));
    }

    return false;
    
  }
  
  
  void loadPoint(Level level, int i, int j, Point pt){
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
          LoadXsbWall(level, pt); 
          break;
        case('.'):
          LoadXsbMarked(level, pt, color); 
          break;
        case('*'):
          LoadXsbMarkedBlock(level, pt, color);
          break;
        case('\$'): 
          LoadXsbBlock(level, pt,color); 
          break;
        case('+'):
          LoadXsbMarkedKye(level, pt,color);
          break;
        case('@'):
          SetXsbKye(level, pt);
          break;
    }
  }
  
  bool FindAGoodWall(Level level, Point pt, {bool rec: true}){
    if ((pt.x==0) || (pt.y==0) || (pt.x>=XYE_HORZ) || (pt.y>=XYE_VERT))
      return false;

    Square sq = level.get(pt);
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
        return FindAGoodWall(level, pt + d.pt, rec: false);
      }) || Direction.all().any((Direction d){
        return FindAGoodWall(level, pt + d.pt);
      });
    }

    return false;
  }
  
}

