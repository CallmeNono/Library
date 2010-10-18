package common;
import java.awt.Color;
import java.awt.Font;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;
import javax.swing.Icon;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JSeparator;
import javax.swing.JTextArea;
import javax.swing.JTextField;


public abstract class WindowGUI extends JPanel implements MouseListener{
	private static final long serialVersionUID = 1L;
	
	public WindowGUI(){
		setLayout(null);
	    setBounds(new Rectangle(0, -1, 1000, 600));
	    setBackground(Color.lightGray);
	}
	
	//M�todos impostos por MouseListener;
	public void mouseClicked(MouseEvent e) {}
	public void mouseEntered(MouseEvent e) {}
	public void mouseExited(MouseEvent e) {}
	public void mousePressed(MouseEvent e) {}
	public void mouseReleased(MouseEvent e) {}
	
	protected void DrawLine(int pos,Color cor, int x,int y,int x1,int y1){
		JSeparator line = new JSeparator(pos);
		line.setBackground(cor);
		line.setBounds(new Rectangle(x,y,x1,y1));
		
		add(line);
	}
	
	protected void CreateButton(String name, Color cor,String toolTip, int size, int x, int y, int x1,int y1){
		JButton botao = new JButton(name);
		botao.setName(name);
		botao.setFont(new Font("sansserif",Font.PLAIN,size));
		botao.setBounds(new Rectangle(x, y, x1, y1));
		botao.setBackground(cor);
		botao.addMouseListener(this);
		botao.setToolTipText(toolTip);
		add(botao);
	}
	
	protected JRadioButton CreateRadioButton(String name, Color cor, boolean selected, int size, int x, int y, int x1,int y1){
		JRadioButton botao = new JRadioButton(name);
		botao.setName(name);
		botao.setFont(new Font("sansserif",Font.PLAIN,size));
		botao.setBounds(new Rectangle(x, y, x1, y1));
		botao.setBackground(cor);
		botao.setSelected(selected);
		botao.addMouseListener(this);
		add(botao);
		
		return botao;
	}

	protected void CreateTitle(String name,Color cor, int size, int x, int y, int x1,int y1){
		JLabel title = new JLabel();
		title.setBounds(new Rectangle(x,y,x1,y1));
		title.setText(name);
		title.setName(name);
		title.setFont(new Font("sansserif",Font.PLAIN,size));
		title.setForeground(cor);
		title.validate();
		add(title);
	}
	
	public JTextField CreateBoxDouble(int size,int x,int y,int x1,int y1,double def){
		JTextField box = new JTextField(size);
		box.setBounds(new Rectangle(x,y,x1,y1));
		box.setText(Double.toString(def));
		add(box);
		
		return box;
	}
	
	public JTextField CreateBoxInt(int size,int x,int y,int x1,int y1,int def){
		JTextField box = new JTextField(size);
		box.setBounds(new Rectangle(x,y,x1,y1));
		box.setText(Integer.toString(def));
		add(box);
		
		return box;
	}
	
	public JTextArea CreateText(int size,int size1,int x,int y, int x1,int y1){
		JTextArea text = new JTextArea(size,size1);
		text.setBounds(new Rectangle(x,y,x1,y1));
		add(text);
		
		return text;
	}
	
	public JLabel CreateImage(String path, String toolTip,int x,int y,int x1,int y1){
		BufferedImage img = null;
		Icon icon;
		JLabel label;
		
		try {
			img = ImageIO.read(new File(path));
		} catch (IOException e){
			System.out.println("Could not open the image located in " + path + "!");
		}
		icon = new ImageIcon(img);
        label = new JLabel(icon);
        label.setBounds(new Rectangle(x,y,x1,y1));
        if (!toolTip.equals(""))
        	label.setToolTipText(toolTip);
        add(label);
        
        return label;
	}
}
