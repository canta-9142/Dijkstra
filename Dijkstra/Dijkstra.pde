// prim法による迷路生成とDijkstra法(A*アルゴリズム)による最短経路探索(Fibbonacciヒープ使用)
// マス距離は固定小数点数としている

// ここの変数はいじってOK
final boolean diagonal = false;       // 斜め移動の可否
final boolean aSter = false;          // A*アルゴリズムの有効化
final boolean generateMaze = false;   // 迷路の自動生成、falseなら障害物を手書き

final int fr = 60;                   // フレームレート
final int perFrame = 2;               // 1フレームあたりの探索数(等倍時)
final int speedRate = 10;             // Fキーを押したときの倍速レート
final int rows = 101, cols = 101;     // 行数列数(迷路生成するときは奇数を推奨)
final int vDist = 1000, dDist = 1414; // マスごとの縦横・斜めそれぞれの距離(縦横は1000、斜めは1414の固定小数点で近似)
final int gridsize = 10, gapsize = 2; // 描画時のマスのサイズとマス間の隙間

// ここからは触らないで
final int w = (gridsize + gapsize) * cols + gapsize;
final int h = (gridsize + gapsize) * rows + gapsize;
int phase, start, goal, count, baseTime, pFrame;
boolean flag, flagRightPressed = false, flagEnterPressed = false, flagKeyPressed = false; // 汎用のフラグ、右クリックを検知するフラグ
Node trace;       // 経路探索用ノード
Node[] marr;      // 主配列
FiboHeap heap;    // フィボナッチヒープ
RandomHeap rHeap; // 迷路生成用ヒープ

void settings() {
  size(w, h);
  noSmooth();
}

void setup() {
  rectMode(CORNER);
  colorMode(RGB, 255, 255, 255);
  noStroke();
  frameRate(fr);

  marr = new Node[rows * cols];
  for (int i = 0; i < rows * cols; i++) marr[i] = new Node(i, aSter, generateMaze);
  heap = new FiboHeap();
  rHeap = new RandomHeap();
  flag = false;
  phase = 1;
  start = -1;
  goal = -1;
  pFrame = perFrame;
  if (generateMaze) {
    // 0,1,2...と続く行数(列数)のランダムな奇数行目(列目)
    int i = (int)random(0, (rows - 2) / 2) * 2 + 1;
    int j = (int)random(0, (cols - 2) / 2) * 2 + 1;
    rHeap.push(marr[i * cols + j]);
    count = -1;
  } else {
    count = 0;
  }
}

void draw() {
  //描画
  drawGrid();

  // 障害物生成段
  if (phase == 1) {
    // 障害物の生成
    // 迷路生成する場合
    if (generateMaze) {
      // prim法
      if (count == -1) {
        for (int i = 0; i < pFrame && !flag; i++) {
          flag = prim();
        }
        if (flag) {
          flag = false;
          count++;
          for (int i = 0; i < rows * cols; i++) marr[i].prev = null;
        }
      }
    }
    // 迷路生成しない場合
    else {
      // XY座標から行数列数を求める
      // 列数:X座標を(gapsize + gridsize)で割った値の小数点以下切り上げ
      // 行数:Y座標を(gapsize + gridsize)で割った値の小数点以下切り上げ
      if (mousePressed) {
        if (mouseButton == LEFT) {
          // クリックしたマスの位置同定→障害物に設定
          // index = row * cols + col
          int row = constrain((mouseY - gapsize) / (gapsize + gridsize), 0, rows - 1);
          int col = constrain((mouseX - gapsize) / (gapsize + gridsize), 0, cols - 1);
          int index = row * cols + col;
          marr[index].state = -1;
        }
      }
    }

    // スタートとゴールの設置
    if (mousePressed && mouseButton == RIGHT) {
      if (!flagRightPressed) {
        // 右クリックした最初のフレームだけここが実行される
        int row = constrain(mouseY / (gapsize + gridsize), 0, rows - 1);
        int col = constrain(mouseX / (gapsize + gridsize), 0, cols - 1);
        if (count == 0) {
          start = row * cols + col;
        }
        else if (count == 1) {
          goal = row * cols + col;
          flag = true;
        }
        count++;
        flagRightPressed = true;
      }
    }
    else {
      flagRightPressed = false;
    }
    
    // スタートおよびゴールが設置された
    if (flag) {
      // 経路探索開始のための準備
      if (start == goal) {
        println("Start and goal are the same position.");
        phase = 4;
        return;
      }
      marr[goal].state = 0; // バグ防止
      heap.push(marr[start]);
      marr[start].state = 1; // スタートを発見済みに
      marr[start].parent = null; // スタートの親はなし
      marr[start].dist = 0; //始点の距離だけ0に
      baseTime = millis();
      flag = false;
      phase = 2;
    }
  }

  // 経路探索段
  else if (phase == 2) {
    // ヒープが空⇒探索できるマスが残っていないので終了
    if (heap.getN() == 0) {
      println("何らかのエラーにより、目的地を見つけられませんでした。");
      phase = 4;
      return;
    }

    // 経路探索
    // A* algorithm
    if (aSter) {
      for (int i = 0; i < pFrame && !flag; i++) {
        flag = aSter();
      }
    }
    // Dijkstra's algorithm
    else {
      for (int i = 0; i < pFrame && !flag; i++) {
        flag = dijkstra();
      }
    }

    // ゴールに到達した
    if (flag) {
      phase = 3;
      flag = false;
      trace = marr[goal];
      println("実行時間: " + (millis() - baseTime) + "ms");
    }
  }

  // 最短経路表示段
  else if (phase == 3) {
    while (trace != marr[start]) {
      marr[trace.prev.index].state = 3;
      trace = trace.prev;
    }
    phase = 4;
    return;
  }

  // 停止段(Rキーが押されるのを待機)
  else if (phase == 4) {
    noLoop();
  }
}

// Prim's algorithm
// 探索(自分のノードに対して隣接するノードをヒープに追加する)
void pSearch(Node curNode, Node nextNode) {
  if (nextNode.prev == null) { // ヒープに存在しないなら追加
    nextNode.prev = curNode;
    rHeap.push(nextNode);
  }
  return;
}
// 1マスの周辺を全て探索
// 全マス埋まるとtrueを返す
boolean prim() {
  // ヒープからランダムに1つ取り出す
  int now = rHeap.popRandom();
  int nowRow = now / cols;
  int nowCol = now % cols;
  
  // 自身を通路とする
  // 迷路生成の場合、stateが-1なら未発見、0は訪問済みを意味することに注意
  // 自身が親ノードである場合
  if(marr[now].prev == null) {
    marr[now].state = 0;
  }
  // 自身が子ノードである場合
  else {
    int between = (now + marr[now].prev.index) / 2; // 自身と、自身の親のノードとの中間にあるノードのインデックス。2つのインデックスの平均は必ずその中間にあるノードのインデックスとなる。
    if (between < 0 || between >= marr.length) {
      println("Error: betweenIndex out of bounds: " + between);
    } else {
      marr[between].state = 0; // 通路として開ける
    }
    marr[now].state = 0;
    marr[now].prev.state = 0;
  }

  // 周辺の探索
  // 2個上
  if (nowRow >= 2) {
    pSearch(marr[now], marr[now - cols * 2]);
  }
  // 2個下
  if (nowRow <= rows - 3) {
    pSearch(marr[now], marr[now + cols * 2]);
  }
  // 2個左
  if (nowCol >= 2) {
    pSearch(marr[now], marr[now - 2]);
  }
  // 2個右
  if (nowCol <= cols - 3) {
    pSearch(marr[now], marr[now + 2]);
  }

  // ヒープが空になってしまったらtrueを返す
  return rHeap.getN() == 0;
}

// Dijkstra's algorithm
// Prim法とやっていることはさほど変わっておらず、斜め方向の処理が追加されたぐらいである。
// 探索(ある一方向について発見するか距離の更新を行う)
void dSearch(Node curNode, Node nextNode, int newDist) {
  if (nextNode.state == 2 || nextNode.state == -1) return;
  
  if (nextNode.state != 1) { // ヒープに存在しない
    nextNode.dist = newDist;
    nextNode.prev = curNode;
    nextNode.state = 1;
    heap.push(nextNode);
  } else {                   // ヒープに存在する
    if (heap.prioritize(nextNode, newDist)) nextNode.prev = curNode;
  }
}
// 1マスの周辺を全て探索
// ゴーを訪問したらtrueを返す
boolean dijkstra() {
  int now = heap.topIndex();
  int nowRow = now / cols;
  int nowCol = now % cols;
  heap.pop();
  if (marr[now].state == 2 || marr[now].state == -1) return false; // 訪問済み、障害物は除く(そもそもpushしてないはずだけど)
  marr[now].state = 2;
  if (now == goal) return true; // ゴールを訪問したなら探索は行う必要がない
  else { // ゴールでない中間ノードである場合探索する
    // 上隣
    if (nowRow != 0) {
      dSearch(marr[now], marr[now - cols], marr[now].dist + vDist);
    }
    // 下隣
    if (nowRow != rows - 1) {
      dSearch(marr[now], marr[now + cols], marr[now].dist + vDist);
    }
    // 左隣
    if (nowCol != 0) {
      dSearch(marr[now], marr[now - 1], marr[now].dist + vDist);
    }
    // 右隣
    if (nowCol != cols - 1) {
      dSearch(marr[now], marr[now + 1], marr[now].dist + vDist);
    }
    // 斜め移動
    if (diagonal) {
      // 左上
      if (nowRow != 0 && nowCol != 0) {
        dSearch(marr[now], marr[now - cols - 1], marr[now].dist + dDist);
      }
      // 右上
      if (nowRow != 0 && nowCol != cols - 1) {
        dSearch(marr[now], marr[now - cols + 1], marr[now].dist + dDist);
      }
      // 左下
      if (nowRow != rows - 1 && nowCol != 0) {
        dSearch(marr[now], marr[now + cols - 1], marr[now].dist + dDist);
      }
      // 右下
      if (nowRow != rows - 1 && nowCol != cols - 1) {
        dSearch(marr[now], marr[now + cols + 1], marr[now].dist + dDist);

      }
    }
  }
  return false;
}

// A* algorithm
// 推定距離
int estimate(int next, int goal) {
  int dx = abs(next % cols - goal % cols);
  int dy = abs(next / cols - goal / cols);
  // Manhattan距離 → 斜めなしの場合正確で一番計算量が少ない
  // Octile距離 → 斜めありの場合正確
  // Euclid距離 → 斜めありの場合正確かつ指向性も許容範囲内でOctileよりノードの探索量を減らせるがsqrt()を使うためノード1個あたりの計算量は増える

  // 斜めなしの場合、OctileとEuclidはより探索量が減るが正確な最短距離を出す保証はない(特に迷路のとき)が、
  // 逆に障害物を手書きするような規模感ではEuclid距離による推定でも十分正確性を得られそうだという発想
  if (!diagonal) {
    if(generateMaze) {
      // Manhattan distance
      return (dx + dy) * vDist;
    } else {
      // Euclidean distance with alignment
      return floor(sqrt(dx * dx + dy * dy) * vDist * 1.619);
    }
  } else {
    // Euclidean distance
    return floor(sqrt(dx * dx + dy * dy) * dDist);
  }
}
// 以下Dijkstra法と全く同じ
void aSearch(Node curNode, Node nextNode, int newDist) {
  if (nextNode.state == 2 || nextNode.state == -1) return;
  
  if (nextNode.state != 1) {
    nextNode.dist = newDist;
    nextNode.est = estimate(nextNode.index, goal);
    nextNode.prev = curNode;
    nextNode.state = 1;
    heap.push(nextNode);
  } else {
    if (heap.prioritize(nextNode, newDist, estimate(nextNode.index, goal))) nextNode.prev = curNode;
  }
}
boolean aSter() {
  int now = heap.topIndex();
  if (now == -1) return false;
  int nowRow = now / cols;
  int nowCol = now % cols;
  heap.pop();
  if (marr[now].state == 2 || marr[now].state == -1) return false;
  if (now == goal) return true;
  else {
    if (nowRow != 0) {
      aSearch(marr[now], marr[now - cols], marr[now].dist + vDist);
    }
    if (nowRow != rows - 1) {
      aSearch(marr[now], marr[now + cols], marr[now].dist + vDist);
    }
    if (nowCol != 0) {
      aSearch(marr[now], marr[now - 1], marr[now].dist + vDist);
    }
    if (nowCol != cols - 1) {
      aSearch(marr[now], marr[now + 1], marr[now].dist + vDist);
    }
    if (diagonal) {
      if (nowRow != 0 && nowCol != 0) {
        aSearch(marr[now], marr[now - cols - 1], marr[now].dist + dDist);
      }
      if (nowRow != 0 && nowCol != cols - 1) {
        aSearch(marr[now], marr[now - cols + 1], marr[now].dist + dDist);
      }
      if (nowRow != rows - 1 && nowCol != 0) {
        aSearch(marr[now], marr[now + cols - 1], marr[now].dist + dDist);
      }
      if (nowRow != rows - 1 && nowCol != cols - 1) {
        aSearch(marr[now], marr[now + cols + 1], marr[now].dist + dDist);
      }
    }
  }
  return false;
}

// 主配列(marr)を描画する
void drawGrid() {
  background(10);
  // rectMode→CORNER
  // rect(左上のx座標, 左上のy座標, 幅, 高さ);
  // x座標 = 列数 * (gridsize + gapsize) + gapsize
  // y座標 = 行数 * (gridsize + gapsize) + gapsize
  // マス番号から行数列数を取得する場合、
  // 行数はマス番号を最大列数で割って小数点以下切り捨て、列数はマス番号を最大列数で割った余り
  
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      if                 (i * cols + j == start) fill( 255, 100,   0); // スタート
      else if            (i * cols + j ==  goal) fill( 255, 255,   0); // ゴール
      else {
        if      (marr[i * cols + j].state ==  1) fill( 255,   0,   0); // 発見済み
        else if (marr[i * cols + j].state ==  2) fill(   0, 255,   0); // 訪問済み
        else if (marr[i * cols + j].state == -1) fill( 180, 130,  80); // 障害物
        else if (marr[i * cols + j].state ==  0) fill(  50,  50,  50); // 未発見
        else if (marr[i * cols + j].state ==  3) fill(   0,   0, 255); // 最短経路
      }
      rect(j * (gridsize + gapsize) + gapsize, i * (gridsize + gapsize) + gapsize, gridsize, gridsize);
    }
  }
}

// fキー、enterキー、rキーの動作
void keyPressed() {
  if (phase == 4 && !flagKeyPressed) { // setup()での動作をもう一度書いてしまっているので直す余地あり
    noLoop();
    marr = new Node[rows * cols];
    for (int i = 0; i < rows * cols; i++) marr[i] = new Node(i, aSter, generateMaze);
    heap = new FiboHeap();
    rHeap = new RandomHeap();
    trace = null;
    flag = false;
    phase = 1;
    start = -1;
    goal = -1;
    if (generateMaze) {
      int i = (int)random(0, (rows - 2) / 2) * 2 + 1;
      int j = (int)random(0, (cols - 2) / 2) * 2 + 1;
      rHeap.push(marr[i * cols + j]);
      count = -1;
    } else {
      count = 0;
    }
    loop();
  }
  if (keyCode == ENTER) {
    if (!flagEnterPressed) {
      flagEnterPressed = true;
      noLoop();
    }
    else {
      flagEnterPressed = false;
      loop();
    }
    flagKeyPressed = true;
  }
  if (key == 'F' || key == 'f') {
    pFrame = perFrame * speedRate;
    flagKeyPressed = true;
  }
}
void keyReleased() {
  pFrame = perFrame;
  flagKeyPressed = false;
}
