SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: LIB_EVALUEVARIABLECIRCUIT
-- Paramètre d'entrée	: @v_idVariable : Identifiant de la variable circuit
--			  @v_idAgv : Identifiant de l'Agv
--			  @v_idPoint : Identifiant point
--			  @v_idAction : Identifiant action
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK : L'évaluation s'est déroulé correctement
--			  - @CODE_KO : Une erreur s'est produite lors de l'exécution de la procédure stockée
--			  d'évaluation de la variable 
--			  - @CODE_KO_INCONNU : la variable passée en paramètre n'existe pas  
--			  @v_valeur : valeur de la variable
-- Descriptif		: Cette procédure évalue une variable circuit
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_EVALUEVARIABLECIRCUIT]
	@v_idVariable integer,
	@v_idAgv tinyint,
	@v_idPoint int = NULL,
	@v_idAction int = NULL,
	@v_valeur integer out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_codeRetour integer,
	@v_proc_name varchar(128),
	@v_valeurParam varchar(128),
	@v_paramEntree varchar(1000),
	@v_traduction int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SPECIFIQUE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SPECIFIQUE = 20

-- Initialisation des variables
	SET @v_codeRetour = @CODE_KO

	-- récupération du nom de la procédure stockée associée à la variable circuit
	-- et ses paramètres d'entrée
	declare c_selectProcedure CURSOR LOCAL FOR
	select VCT_NomProc,PVC_Valeur
	from VARIABLE_CIRCUIT left outer join PARAMETRE_VARIABLE_CIRCUIT on (VCT_IdVariable = PVC_IdVariable)
	where (VCT_IdVariable = @v_idVariable)
	order by PVC_Position 
	
	-- ouverture du curseur
	open c_selectProcedure
	fetch next from c_selectProcedure INTO @v_proc_name,@v_valeurParam
	while (@@FETCH_STATUS = 0)
	begin
		-- construction de la chaîne des paramètres d'entrée
		if (@v_paramEntree is not NULL)
		begin
			set @v_paramEntree = @v_paramEntree + ',' + @v_valeurParam  
		end
	else
	begin
		set @v_paramEntree = @v_valeurParam
	end
	-- passage au paramètre suivant
	fetch next from c_selectProcedure INTO @v_proc_name,@v_valeurParam
	end

	-- fermeture du curseur
	close c_selectProcedure
	deallocate c_selectProcedure

	if (@v_proc_name is NULL)
	begin
		-- la variable circuit passée en paramètre n'existe pas
		set @v_codeRetour = @CODE_KO_INCONNU 
	end
	else
	begin
		if (@v_paramEntree is NULL)
			exec @v_codeRetour = @v_proc_name @v_idAgv, @v_idPoint, @v_idAction, @v_idVariable, @v_valeur out, @v_traduction out
		else
			exec @v_codeRetour = @v_proc_name @v_idAgv, @v_idPoint, @v_idAction, @v_idVariable, @v_paramEntree, @v_valeur out, @v_traduction out
		if @v_codeRetour <> @CODE_OK
			set @v_codeRetour = @CODE_KO_SPECIFIQUE
		if @v_codeRetour = @CODE_OK AND @v_traduction IS NOT NULL
			UPDATE INFO_AGV SET IAG_POINTARRET = @v_traduction WHERE IAG_ID = @v_idAgv
	end 

	return @v_codeRetour


