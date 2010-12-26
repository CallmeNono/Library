-- Adds a new reader to the data base.
CREATE OR REPLACE PROCEDURE addReader ( nomePessoa IN Pessoa.nome_pessoa%type, morada IN Pessoa.morada%type, bi IN NUMBER,telefone IN NUMBER, email IN Pessoa.e_mail%type) IS
	current_id NUMBER;
	
BEGIN
	SELECT seq_id_pessoa.nextval INTO current_id
	FROM dual;
	
	INSERT INTO Pessoa VALUES (nomePessoa, morada, bi, telefone, email, current_id);
	INSERT INTO Leitor VALUES (current_id, 0);
		
	COMMIT;
	
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		current_id := -1;
	WHEN OTHERS THEN
		current_id := -1;
		
END;

/


CREATE OR REPLACE PROCEDURE addEmployee ( nomePessoa IN Pessoa.nome_pessoa%type, morada IN Pessoa.morada%type, bi IN NUMBER,telefone IN NUMBER, email IN Pessoa.e_mail%type) IS
	current_id NUMBER;
	
BEGIN
	SELECT seq_id_pessoa.nextval INTO current_id
	FROM dual;
	
	INSERT INTO Pessoa VALUES (nomePessoa, morada, bi, telefone, email, current_id);
	INSERT INTO Funcionario VALUES (current_id, sysdate, null);
		
	COMMIT;
	
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		current_id := -1;
		-- Error raised when we insert the same BI.
		--TODO:  Return an appropriate value. Maybe we have to create a OUT variable
	WHEN OTHERS THEN
		--TODO: The same as above.
		current_id := -1;
	
END;

/

create or replace function getPrateleira (gen IN PRATELEIRA.GENERO%type, total IN PUBLICACAO.TOTAL%type) return PRATELEIRA.ID_PRATELEIRA%type is

prat PRATELEIRA.ID_PRATELEIRA%type:=-1;

cursor shelf is
	select id_prateleira from prateleira where upper(genero) like upper(gen) and (OCUPACAO+total)<CAPACIDADE;


begin

open shelf;
fetch shelf into prat;
close shelf;

return prat;	

Exception
	when no_data_found then
		return prat;
	
return prat;
	
end;

/


create or replace function getEditora (edi IN EDITORA.NOME_EDITORA%type) return EDITORA.ID_EDITORA%type is

edit EDITORA.ID_EDITORA%type:=-1;

begin

select ID_EDITORA into edit from editora where upper(NOME_EDITORA) like upper(edi);

return edit;

Exception
	when no_data_found then
		return edit;
	
end;

/


-- falta verificar a questao das prateleiras! atencao a rollbacks!
CREATE OR REPLACE PROCEDURE addDocument ( Aut IN AUTOR.NOME_AUTOR%type, Edi IN EDITORA.NOME_EDITORA%type,
											gen IN PRATELEIRA.GENERO%type,
											pages IN PUBLICACAO.PAGINAS%type,
											descri IN PUBLICACAO.DESCRICAO%type,
											DATA IN PUBLICACAO.DATA%type, nome IN PUBLICACAO.NOME_DOC%type, 
											total IN PUBLICACAO.TOTAL%type, retVal OUT INTEGER) IS
	current_id NUMBER;
	idAut AUTOR.ID_AUTOR%type;
	idEdi EDITORA.ID_EDITORA%type;
	idPra PRATELEIRA.ID_PRATELEIRA%type;
	
BEGIN
	Begin
		select id_autor into idAut from Autor where upper(nome_autor) like upper(Aut);
		if SQL%ROWCOUNT>1 then
			retval := -1;
			return;
		end if;
		
		Exception
			when no_data_found then
				SELECT seq_id_author.nextval INTO idAut FROM dual;
				insert into AUTOR values (Aut,idAut);
	end;
	
	idPra := getPrateleira(gen,total);
	
	if idPra=-1 then --n existem prateleiras para esse genero
		SELECT seq_id_shelf.nextval INTO idPra FROM dual;
		insert into prateleira values(20,0,idPra,gen);
	end if;
	
	idEdi := getEditora(Edi);
	
	if idEdi=-1 then 
		SELECT seq_id_publisher.nextval INTO idEdi FROM dual;
		insert into editora values (idEdi,Edi);
	end if;


	SELECT seq_id_document.nextval INTO current_id
	FROM dual;
	
	INSERT INTO PUBLICACAO VALUES (current_id, idPra, idAut, idEdi, pages, descri, DATA, nome, total, total);
	update prateleira set OCUPACAO=OCUPACAO+total where ID_PRATELEIRA = idPra;
	
	retVal :=1;
		
	COMMIT;
	
END;

/


--penso que esta a funcionar como deve ser. verificar melhor
CREATE OR REPLACE TRIGGER checkShelf AFTER UPDATE ON Publicacao FOR EACH ROW

DECLARE

	oldPratRow PRATELEIRA%ROWTYPE;
	newPratRow PRATELEIRA%ROWTYPE;
	pub publicacao%rowtype;
	idPra PRATELEIRA.ID_PRATELEIRA%type;

begin
	--Procuramos se a prateleira q ja contem estas publicacoes tem espaco. se nao devolver nada, entao significa q ainda existe espaco nessa prateleira
	select * into oldPratRow from prateleira where :old.id_prateleira = id_prateleira 
		AND (capacidade < OCUPACAO +(:new.total-:old.total));
		
	BEGIN
		--Procuramos um prateleira do mesmo genero que tenha espaco
		select * into newPratRow from prateleira where (capacidade >= OCUPACAO +(:new.total)) 
			AND genero like oldPratRow.genero;
		
		Exception 
			--se nao existir entao criamos uma nova
			when no_data_found then
				SELECT seq_id_shelf.nextval INTO idPra FROM dual;
				insert into prateleira values(20,0,idPra,oldPratRow.genero);
					select * into newPratRow from prateleira where (capacidade >= OCUPACAO +(:new.total)) 
						AND genero like oldPratRow.genero;
	end;

	update prateleira set OCUPACAO=OCUPACAO+:new.total where ID_PRATELEIRA = newPratRow.id_prateleira;
	update prateleira set OCUPACAO=OCUPACAO-:old.total where ID_PRATELEIRA = oldPratRow.id_prateleira;
	
	Exception
		when no_data_found then
			return;

end;

/

-- falta verificar a questao das prateleiras!
CREATE OR REPLACE PROCEDURE addCopyDocument(idDoc IN PUBLICACAO.ID_DOC%type, novos IN PUBLICACAO.TOTAL%type) IS


BEGIN
	UPDATE PUBLICACAO
	SET DISPONIVEIS=DISPONIVEIS+novos, TOTAL=TOTAL+novos
	WHERE id_doc = idDoc;

	COMMIT;

EXCEPTION
	WHEN no_data_found THEN
		RETURN;

END;

/	


-- Script used to make requisitions.
CREATE OR REPLACE PROCEDURE newRequisition ( book_id IN Publicacao.id_doc%type, reader_id IN Pessoa.id_pessoa%type, employee_id IN Pessoa.id_pessoa%type) IS
	no_available INTEGER; 
	id_pessoa_conf INTEGER; 
	current_id NUMBER;
	
	ID_NOT_FOUND exception; 
	PRAGMA exception_init(ID_NOT_FOUND, -2291); 
	
BEGIN 
	SELECT seq_id_aluguer.nextval INTO current_id
	FROM dual;
	
	SELECT p.disponiveis INTO no_available 
	FROM Publicacao p 
	WHERE p.id_doc = book_id; 
	
	IF (no_available > 0) THEN 
		UPDATE Publicacao p SET p.disponiveis = p.disponiveis - 1 
		WHERE p.id_doc = book_id; 
		
		UPDATE Leitor SET no_emprestimos = no_emprestimos + 1
		WHERE id_pessoa = reader_id;
		
		INSERT INTO Emprestimo VALUES (reader_id, employee_id, book_id, current_id, SYSDATE, SYSDATE + 7, null ); 
		 
	ELSE 
		id_pessoa_conf := -1; 
	END IF; 
	
	COMMIT; 
	
EXCEPTION 
	WHEN NO_DATA_FOUND THEN 
		id_pessoa_conf := -1; 
	WHEN ID_NOT_FOUND THEN 
		id_pessoa_conf := -1; 

END;

/

-- STATISTICS

-- Employees
CREATE OR REPLACE PROCEDURE employeesStats (no_entries OUT INTEGER, fired_employees OUT INTEGER, avg_working_time OUT FLOAT) IS
	
BEGIN
	
	-- Checks the number of entries
	BEGIN
		SELECT COUNT(*) INTO no_entries
		FROM Funcionario;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_entries := 0;
	END;
	
	-- Checks the number of fired employees, meaning the ones who have an exit date
	BEGIN
		SELECT COUNT(*) INTO fired_employees
		FROM Funcionario
		WHERE Data_saida IS NOT NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_entries := 0;
	END;
	
	BEGIN
		-- If the employees hasn't been fired, we consider the actual date as the exit date, just for counting purposes.
		SELECT ROUND(AVG(NVL(Data_saida, SYSDATE) - Data_entrada), 2) INTO avg_working_time
		FROM Funcionario;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_working_time := 0;
	END;
	
	
	COMMIT;
	

END;
/


-- Readers
CREATE OR REPLACE PROCEDURE readersStats (no_entries OUT INTEGER, readers_with_books OUT INTEGER, faulty_readers OUT INTEGER) IS
	
BEGIN
	
	-- Checks the number of entries
	BEGIN
		SELECT COUNT(*) INTO no_entries
		FROM Leitor;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_entries := 0;
	END;
	
	-- Checks the number of fired employees, meaning the ones who have an exit date
	BEGIN
		SELECT COUNT(*) INTO readers_with_books
		FROM Emprestimo
		WHERE Data_entrega IS NULL
		GROUP BY LEI_ID_PESSOA;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			readers_with_books := 0;
	END;
	
	BEGIN
		-- If the employees hasn't been fired, we consider the actual date as the exit date, just for counting purposes.
		SELECT COUNT(*) INTO faulty_readers
		FROM Emprestimo
		WHERE Data_prevista - SYSDATE < 0 AND Data_entrega IS NULL
		GROUP BY LEI_ID_PESSOA;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			faulty_readers := 0;
	END;
	
	
	COMMIT;
	

END;
/

-- Books and Shelves
CREATE OR REPLACE PROCEDURE booksAndShelvesStats (no_books OUT INTEGER, max_pages OUT INTEGER, min_pages OUT INTEGER,
													avg_pages OUT FLOAT, avg_copies OUT FLOAT, no_shelves OUT INTEGER,
													occupation OUT FLOAT, avg_capacity OUT FLOAT) IS
	
BEGIN
	
	-- Checks the number of books
	BEGIN
		SELECT COUNT(*) INTO no_books
		FROM Publicacao;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_books := 0;
	END;
	
	-- max pages
	BEGIN
		SELECT MAX(Paginas) INTO max_pages
		FROM Publicacao;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			max_pages := 0;
	END;
	
	-- min pages
	BEGIN
		SELECT MIN(Paginas) INTO min_pages
		FROM Publicacao;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			min_pages := 0;
	END;
	
	-- Check the average number of copies per publication
	BEGIN
		SELECT ROUND(AVG(Paginas),2) INTO avg_pages
		FROM Publicacao;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_pages := 0;
	END;
	
	-- Check the average number of copies per publication
	BEGIN
		SELECT ROUND(AVG(Total),2) INTO avg_copies
		FROM Publicacao;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_copies := 0;
	END;
	
	
	
	-- SHELVES
	
	-- Checks the number of books
	BEGIN
		SELECT COUNT(*) INTO no_shelves
		FROM Prateleira;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_shelves := 0;
	END;
	
	-- Checks the occupation rate of the shelves
	BEGIN
		SELECT ROUND(SUM(OCUPACAO)/SUM(CAPACIDADE), 2) INTO occupation
		FROM Prateleira;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			occupation := 0;
	END;
	
	
	-- Checks the number of books
	BEGIN
		SELECT ROUND(AVG(CAPACIDADE),2) INTO avg_capacity
		FROM Prateleira;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_capacity := 0;
	END;
	
	
	COMMIT;
	

END;
/

-- Requisitions
CREATE OR REPLACE PROCEDURE requisitionsStats (no_entries OUT INTEGER, on_going_reqs OUT INTEGER, finished_reqs OUT INTEGER,
												no_faulty_reqs OUT INTEGER, avg_reqs_per_day OUT FLOAT, no_days_with_reqs OUT INTEGER) IS
	
BEGIN
	
	-- Checks the number of requisitons
	BEGIN
		SELECT COUNT(*) INTO no_entries
		FROM Emprestimo;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_entries := 0;
	END;
	
	-- Checks the number of on going requisitons
	BEGIN
		SELECT COUNT(*) INTO on_going_reqs
		FROM Emprestimo
		WHERE Data_entrega IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			on_going_reqs := 0;
	END;
	
	-- Checks the number of finished requisitions
	BEGIN
		SELECT COUNT(*) INTO finished_reqs
		FROM Emprestimo
		WHERE Data_entrega IS NOT NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			finished_reqs := 0;
	END;
	
	-- Checks the average of requisitions per day, counting only days with at least one requisition
	BEGIN
		SELECT ROUND(AVG(TO_CHAR(DATA_DE_REQUISITO,'yyyy-mm-dd')),2) INTO avg_reqs_per_day
		FROM Emprestimo
		GROUP BY TO_CHAR(DATA_DE_REQUISITO,'yyyy-mm-dd');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_reqs_per_day := 0;
	END;
	
	-- Checks the number of days with requisitions
	BEGIN
		SELECT COUNT(*) INTO no_days_with_reqs
		FROM Emprestimo
		GROUP BY TO_CHAR(DATA_DE_REQUISITO,'yyyy-mm-dd');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_days_with_reqs := 0;
	END;
	
	
	COMMIT;
	

END;
/


-- Authors and Publishers
CREATE OR REPLACE PROCEDURE authorsAndPublishersStats (no_authors OUT INTEGER, avg_doc_per_author OUT FLOAT,
														no_publishers OUT INTEGER, avg_doc_per_publisher OUT FLOAT) IS
	
BEGIN
	
	-- AUTHORS
	-- Checks the number of entries
	BEGIN
		SELECT COUNT(*) INTO no_authors
		FROM Autor;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_authors := 0;
	END;
	
	-- Checks the average of copies per author
	BEGIN
		SELECT ROUND(AVG(Total), 2) INTO avg_doc_per_author
		FROM Publicacao
		GROUP BY ID_AUTOR;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_doc_per_author := 0;
	END;
	
	-- PUBLISHERS
	
	-- Checks the number of entries
	BEGIN
		SELECT COUNT(*) INTO no_publishers
		FROM Editora;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			no_publishers := 0;
	END;
	
	-- Checks the average of copies per publisher
	BEGIN
		SELECT ROUND(AVG(Total),2) INTO avg_doc_per_publisher
		FROM Publicacao
		GROUP BY ID_EDITORA;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			avg_doc_per_publisher := 0;
	END;
	
	
	COMMIT;
	

END;
/
