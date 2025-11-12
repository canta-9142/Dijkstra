import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

// ここの変数はいじってOK
final boolean diagonal = false;       // 斜め移動の可否
final boolean aStar = true;          // A*アルゴリズムの有効化
final boolean generateMaze = true;   // 迷路の自動生成、falseなら障害物を手書き

final int fr = 10;                   // フレームレート
final int perFrame = 1;               // 1フレームあたりの探索数(等倍時)
final int speedRate = 10;             // Fキーを押したときの倍速レート
final int rows = 31, cols = 31;     // 行数列数(迷路生成するときは奇数を推奨)
final int vDist = 1000, dDist = 1414; // マスごとの縦横・斜めそれぞれの距離(縦横は1000、斜めは1414の固定小数点で近似)
final int gridsize = 10, gapsize = 2; // 描画時のマスのサイズとマス間の隙間

// ここからは触らないで
final int w = (gridsize + gapsize) * cols + gapsize;
final int h = (gridsize + gapsize) * rows + gapsize;
final int PHASE_GENERATE = 0, PHASE_PLACE = 1, PHASE_SEARCH = 2, PHASE_TRACE = 3, PHASE_STOP = 4;
int phase = PHASE_GENERATE, pFrame = perFrame;
boolean flagEnterPressed = false;
Node start, goal, trace;       // 経路探索用ノード
Node[] grid;      // 主配列
Heap heap;    // ヒープ(優先度付きキュー)
RandomHeap rHeap; // 迷路生成用ヒープ

// 列と行からインデックスを返す
int index(int i, int j)
{
    return i * cols + j;
}
// グリッドの初期化
void createGrid(boolean a, boolean g)
{
    grid = new Node[rows * cols];
    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            grid[index(i,j)] = new Node(index(i,j),a,g);
        }
    }
    heap = new Heap();
    rHeap = new RandomHeap();
    start = null;
    goal = null;
    trace = null;

    if (g)
    {
        int i = (int)Math.floor(random(0, rows - 2) / 2) * 2 + 1;
        int j = (int)Math.floor(random(0, cols - 2) / 2) * 2 + 1;
        rHeap.push(grid[index(i,j)]);
    }
}
// 障害物はそのままにスタートとゴールを再配置
void resetGrid(boolean a, boolean g)
{ 
    for(int i = 0; i < rows; i++)
    {
        for(int j = 0; j < cols; j++)
        {
            Node n = grid[index(i,j)];
            if (n.state != Node.States.Blocked) n.state = Node.States.Undiscovered;
            n.dist = Integer.MAX_VALUE;
            n.est = a ? Integer.MAX_VALUE : 0;
            n.prev = null;
            n.parent = null;
            n.child = null;
            n.left = n;
            n.right = n;
            n.degree = 0;
            n.mark = false;
        }
    }
    heap = new Heap();
    start = null;
    goal = null;
    trace = null;
}
void beginGenerating()
{
    createGrid(aStar, generateMaze);
    phase = PHASE_GENERATE;
    println("begin generating");
    loop();
}
void beginPlacing()
{
    resetGrid(aStar, generateMaze);
    phase = PHASE_PLACE;
    println("begin placing");
    loop();
}
void beginSearching()
{
    if (start == null || goal == null)
    {
        println("StartまたはGoalが設定されていません。もう一度配置してください。");
        beginPlacing();
        return;
    }
    start.state = Node.States.Discovered;
    start.dist = 0;
    heap.push(start);
    phase = PHASE_SEARCH;
    println("begin searching");
    loop();
}

boolean prim()
{
    println("pop: " + rHeap.head.index + " cost=" + rHeap.head.totalCost());
    Node cur = rHeap.pop();
    if (cur == null) return false;

    if (cur.prev == null) cur.state = Node.States.Undiscovered;
    else
    {
        int betweenIndex = (cur.index + cur.prev.index) / 2;
        grid[betweenIndex].state = Node.States.Undiscovered;
        cur.state = Node.States.Undiscovered;
        cur.prev.state = Node.States.Undiscovered;
    }

    List<Node> neighbors = new ArrayList<Node>();
    int row = cur.index / cols;
    int col = cur.index % cols;
    if (row >= 2) neighbors.add(grid[index(row - 2, col)]);
    if (row <= rows - 3) neighbors.add(grid[index(row + 2, col)]);
    if (col >= 2) neighbors.add(grid[index(row, col - 2)]);
    if (col <= cols - 3) neighbors.add(grid[index(row, col + 2)]);

    for (int i = neighbors.size() - 1; i > 0; i--) // Fisher-Yates shuffle
    {
        int j = (int)Math.floor(Math.random() * (i + 1));
        Collections.swap(neighbors, i, j);
    }

    for (Node n : neighbors) pStep(cur, n);

    boolean result = rHeap.N() == 0;
    println(rHeap.N());
    return result;
}
void pStep(Node curNode, Node nextNode)
{
    if (nextNode.prev == null) { // ヒープに存在しないなら追加
        rHeap.push(nextNode);
        nextNode.prev = curNode;
    }
    return;
}

boolean stepSearch()
{
    Node cur = heap.pop();
    if (cur == null) return false;

    int row = cur.index / cols;
    int col = cur.index % cols;
    if (cur.state == Node.States.Visited || cur.state == Node.States.Blocked) return false;
    cur.state = Node.States.Visited;

    if (cur == goal) return true;
    else
    {
        if (aStar)
        {
            if (row != 0) aStep(cur, grid[index(row - 1, col)], cur.dist + vDist);
            if (row != rows - 1) aStep(cur, grid[index(row + 1, col)], cur.dist + vDist);
            if (col != 0) aStep(cur, grid[index(row, col - 1)], cur.dist + vDist);
            if (col != cols - 1) aStep(cur, grid[index(row, col + 1)], cur.dist + vDist);
            if (diagonal)
            {
                if (row != 0 && col != 0) aStep(cur, grid[index(row - 1, col - 1)], cur.dist + dDist);
                if (row != 0 && col != cols - 1) aStep(cur, grid[index(row - 1, col + 1)], cur.dist + dDist);
                if (row != rows - 1 && col != 0) aStep(cur, grid[index(row + 1, col - 1)], cur.dist + dDist);
                if (row != rows - 1 && col != cols - 1) aStep(cur, grid[index(row + 1, col + 1)], cur.dist + dDist);
            }
        }
        else
        {
            if (row != 0) dStep(cur, grid[index(row - 1, col)], cur.dist + vDist);
            if (row != rows - 1) dStep(cur, grid[index(row + 1, col)], cur.dist + vDist);
            if (col != 0) dStep(cur, grid[index(row, col - 1)], cur.dist + vDist);
            if (col != cols - 1) dStep(cur, grid[index(row, col + 1)], cur.dist + vDist);
            if (diagonal)
            {
                if (row != 0 && col != 0) dStep(cur, grid[index(row - 1, col - 1)], cur.dist + dDist);
                if (row != 0 && col != cols - 1) dStep(cur, grid[index(row - 1, col + 1)], cur.dist + dDist);
                if (row != rows - 1 && col != 0) dStep(cur, grid[index(row + 1, col - 1)], cur.dist + dDist);
                if (row != rows - 1 && col != cols - 1) dStep(cur, grid[index(row + 1, col + 1)], cur.dist + dDist);
            }
        }
    }
    return false;
}
void dStep(Node cur, Node next, int newDist)
{
    if (next.state == Node.States.Visited || next.state == Node.States.Blocked) return;

    if (next.state != Node.States.Discovered)
    {
        next.dist = newDist;
        next.prev = cur;
        next.state = Node.States.Discovered;
        heap.push(next);
    }
    else
    {
        if (heap.prioritize(next, newDist)) next.prev = cur;
    }
}
void aStep(Node cur, Node next, int newDist)
{
    if (next.state == Node.States.Visited || next.state == Node.States.Blocked) return;

    int newEst = estimate(next);
    if (next.state != Node.States.Discovered)
    {
        next.dist = newDist;
        next.est = newEst;
        next.prev = cur;
        next.state = Node.States.Discovered;
        heap.push(next);
    }
    else
    {
        if (heap.prioritize(next, newDist, newEst)) next.prev = cur;
    }
}
int estimate(Node next)
{
    int dx = abs(next.index % cols - goal.index % cols);
    int dy = abs(next.index / cols - goal.index / cols);
    if (!diagonal) {
        if(generateMaze) {
        return (dx + dy) * vDist;
        } else {
        return floor(sqrt(dx * dx + dy * dy) * vDist * 1.619);
        }
    } else {
        return floor(sqrt(dx * dx + dy * dy) * dDist);
    }
}

void drawGrid()
{
    background(10);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            int index = index(i, j);
            if          (grid[index] == start)                          fill( 255, 100,   0); // スタート
            else if     (grid[index] ==  goal)                          fill( 255, 255,   0); // ゴール
            else {
                if      (grid[index].state == Node.States.Blocked     ) fill( 180, 130,  80); // 障害物
                else if (grid[index].state == Node.States.Undiscovered) fill(  50,  50,  50); // 未発見
                else if (grid[index].state == Node.States.Discovered  ) fill( 255,   0,   0); // 発見済み
                else if (grid[index].state == Node.States.Visited     ) fill(   0, 255,   0); // 訪問済み
                else if (grid[index].state == Node.States.Path        ) fill(   0,   0, 255); // 最短経路
            }
            rect(
                j * (gridsize + gapsize) + gapsize,
                i * (gridsize + gapsize) + gapsize,
                gridsize,
                gridsize
            );
        }
    }
}

void settings()
{
    size(w, h);
    noSmooth();
}
void setup()
{
    println("setup");
    rectMode(CORNER);
    colorMode(RGB, 255, 255, 255);
    noStroke();
    frameRate(fr);

    beginGenerating();
}
void draw()
{
    //描画
    drawGrid();

    // 障害物生成段
    if (phase == PHASE_GENERATE)
    {
        if (!generateMaze)
        {
            beginPlacing();
            return;
        }
        for (int i = 0; i < pFrame; i++)
        {
            if (prim()){
                beginPlacing();
                break;
            }
        }
    }

    else if (phase == PHASE_PLACE)
    {

    }

    else if (phase == PHASE_SEARCH)
    {
        if (heap.N() == 0)
        {
            print("目的地を見つけられませんでした。Rキーではじめからやり直すか、Cキーで再度スタートとゴールの配置を行ってください。");
            phase = PHASE_STOP;
            return;
        }
        for (int i = 0; i < pFrame; i++)
        {
            if (stepSearch())
            {
                phase = PHASE_TRACE;
                trace = goal;
                break;
            }
        }
        return;
    }

    else if (phase == PHASE_TRACE)
    {
        while (trace != start)
        {
            if (trace.prev == null) break;
            trace.prev.state = Node.States.Path;
            trace = trace.prev;
        }
        phase = PHASE_STOP;
        return;
    }

    else if (phase == PHASE_STOP) {
        noLoop();
        return;
    }
}
void mousePressed()
{
    if (phase != PHASE_PLACE) return;
    if (mouseButton == RIGHT)
    {
        int j = mouseX / (gridsize + gapsize);
        int i = mouseY / (gridsize + gapsize);
        if (i < 0 || i >= rows || j < 0 || j >= cols) return;
        Node node = grid[index(i, j)];
        if (node.state == Node.States.Blocked) return;
        if      (start == null)                 start = node;
        else if (goal == null && node == start) start = null;
        else
        {
            goal = node;
            beginSearching();
        }
    }
} 
void keyPressed()
{
    if (keyCode == ENTER) {
        if (!flagEnterPressed) {
            flagEnterPressed = true;
            noLoop();
        }
        else {
            flagEnterPressed = false;
            loop();
        }
    }
    if (key == 'F' || key == 'f') {
        pFrame = perFrame * speedRate;
    }
    if (key == 'R' || key == 'r') {
        beginGenerating();
    }
    if (key == 'C' || key == 'c') {
        beginPlacing();
    }
}
void keyReleased()
{
    pFrame = perFrame;
}
