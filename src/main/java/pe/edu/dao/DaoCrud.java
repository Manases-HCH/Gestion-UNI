
package pe.edu.dao;

import java.util.LinkedList;

public interface DaoCrud<T> {
    public LinkedList<T> listar();
    public void insertar(T obj);
    public T leer(String id);
    public void editar(T obj);
    public void eliminar(String id);
}
