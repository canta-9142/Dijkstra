// Fibonacci Heap風の優先度付きキュー

import java.util.List;
import java.util.ArrayList;

public class Heap
{
    // private static final double LOG_PHI = 0.4812118251;

    protected Node head;
    protected int n;

    public Heap()
    {
        this.head = null;
        this.n = 0;
    }
    public Node Head() {return this.head;}
    public int N() {return this.n;}

    public void push(Node node)
    {
        if (head == null) head = node;
        else head.insertLeft(node);
        if (node.totalCost() < head.totalCost()) this.head = node;
        n++;
        return;
    }

    public Node pop()
    {
        if (head == null) return null;
        Node min = this.head;
        Node next = head.right;
        head.peel(head);
        head.remove();
        head = min == next ? null : next;
        n--;
        this.setNewHead();
        return min;
    }

    protected void setNewHead()
    {
        if (head == null) return;
        Node cur = head.right;
        Node temp = head;
        while (cur != head) {
            if (cur.totalCost() < temp.totalCost()) {
            temp = cur;
            }
            cur = cur.right;
        }
        head = temp;
        return;
    }

    public boolean prioritize(Node x, int newDist)
    {
        if (newDist >= x.dist) return false;
        x.dist = newDist;

        if (x.parent == null) {
            if (x.dist < head.dist) head = x;
            return true;
        }

        cut(x);
        cascadingCut(x.parent);
        
        if (x.dist < head.dist) head = x;
        return true;
    }
    //A*用
    public boolean prioritize(Node x, int newDist, int newEst)
    {
        if (newDist + newEst >= x.totalCost()) return false;
        x.dist = newDist;
        x.est = newEst;

        if (x.parent == null) {
            if (x.totalCost() < head.totalCost()) head = x;
            return true;
        }
        
        cut(x);
        cascadingCut(x.parent);

        if (x.totalCost() < head.totalCost()) head = x;
        return true;
    }

    private void cut(Node x)
    {
        Node y = x.parent;
        if (y == null) return;
        if (y.child == x) y.child = x.right == x ? null : x.right;
        y.degree--;
        x.remove();
        x.parent = null;
        x.mark = false;
        if (head == null) head = x;
        else head.insertLeft(x);
    }
    private void cascadingCut(Node y)
    {
        while (y != null)
        {
            if (!y.mark)
            {
                y.mark = true;
                break;
            }
            if (y.parent == null) break;
            Node z = y.parent;
            cut(y);
            y = z;
        }
    }

    // 同じdegreeの根ノードが根リストに存在しないように整理する
    // Fibonacci Heapの根幹部分
    // だいぶ前に書いたコードでどういう動作か説明できないし、これが効いてくるのはもっと大きなヒープを扱うときなので、今は使用していない。
    /*
    private void consolidate() {
        int arraySize = (int) Math.floor(Math.log(n) / LOG_PHI) + 2; 
        Node[] A = new Node[arraySize]; //次数iの根ノードをA[i]に格納する

        Node cur = head;
        Node next;
        do {
            next = cur.right;
            while (A[cur.degree] != null) {
            if (cur.totalCost() >= A[cur.degree].totalCost()) { // 入れ替える必要がない場合→curを子にくっつけて次のA[i]を見る
                A[cur.degree].insertChild(cur.remove());
                A[cur.degree].degree++;
                cur = A[cur.degree];
                A[cur.degree] = null;
            }
            else { // Aを更新する(curとA[i]を入れ替える必要がある)場合
                cur.insertChild(A[cur.degree]);
                A[cur.degree] = null;
                cur.remove();
                cur.degree++;
            }
            }
            A[cur.degree] = cur;
            cur = next;
        } while (cur != head);
    }
    */
}
