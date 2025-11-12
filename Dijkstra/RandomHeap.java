public class RandomHeap extends Heap
{
    private Node oldest;

    public RandomHeap()
    {
        super();
        this.oldest = null;
    }

    @Override
    public void push(Node node)
    {
        super.push(node);
        if (oldest == null) oldest = node;
        return;
    }

    @Override
    public Node pop()
    {
        if (head == null) return null;
        setNewHead();
        Node min = head;
        head.peel(head);
        head.remove();
        n--;
        head = min == oldest ? null : oldest;
        return min;
    }

    @Override
    protected void setNewHead()
    {
        if (head == null) return;

        double r = Math.random();
        int index = (int)Math.floor(Math.pow(r - 0.5, 2) * this.n);
        Node cur = head;
        for (int i = 0; i <= index; i++) cur = cur.left;
        head = cur;
    }
}
