SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_RELANCEORDRE
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant AGV
--			  @v_idOrdre : Identifiant de l'ordre Agv à relancer
--			  @v_idMission : Identifiant de la mission de la tâche à relancer
--			  @v_codeRelance : Spécifie s'il s'agit d'une relance explicite
--			  (ex : relance mission) ou s'il s'agit d'une relance interne 
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'ordre est relancé
--			    - @CODE_KO : L'ordre n'est pas relancé car il est encore associé à une tâche non relancée
--			    - @CODE_KO_SQL : Une erreur s'est produite lors de la relance
-- Descriptif		: Cette procédure relance un ordre agv stoppé:
--			  Les tâches associées passent dans un état de relance: ID_ETAT_RELANCE
--			  Lorsque toutes les tâches sont dans cet état, on analyse les bases des
--			  tâches :
--			    - Si les bases sont identiques, l'ordre peut être relancé: il passe dans l'état attente.
--			    - Si les bases sont différentes, on crée autant d'ordres successsifs que de (bases différentes - 1)
--			    et on les associent aux tâches. Puis l'ordre est relancé. (Attention, il s'agit d'un
--			    mode dégradé, les ordres ne sont pas ordonnés. Il sont consécutifs à l'ordre stoppé).
--			  Au prochain réveil de l'agv, l'ordre repassera en cours
--			  et on lancera l'ordre d'exécution au pilotage Agv
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_RELANCEORDRE]
	@v_iag_idagv int,
	@v_ord_idordre int,
	@v_mis_idmission int,
	@v_relance tinyint
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
	@v_positionTache tinyint,
	@v_positionOrdre integer,
	@v_positionOrdreSuiv integer,
	@v_isFirstTache bit,
	@v_adrSysOrdre bigint,
	@v_adrBaseOrdre bigint,
	@v_adrSys bigint,
	@v_adrbase bigint,
	@v_idAgv tinyint,
	@v_ord_position int

-- Déclaration des constantes d'états et descriptions de missions
DECLARE
	@DESC_REVISION tinyint,
	@DESC_RELANCE_MISSION tinyint,
	@DESC_RELANCE_INTERNE tinyint

-- Déclaration des constantes des états tâches et ordres
DECLARE
	@ID_ETAT_ATTENTE tinyint,
	@ID_ETAT_STOP tinyint

-- Déclaration des constantes de types d'ordres
DECLARE
	@TYPE_MOUVEMENT bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SET @ID_ETAT_ATTENTE = 1
	SET @ID_ETAT_STOP = 3
	SET @CODE_OK=0
	SET @CODE_KO=1
	SET @CODE_KO_SQL=13
	SET @DESC_REVISION = 7
	SET @DESC_RELANCE_MISSION = 10
	SET @DESC_RELANCE_INTERNE = 11
	SET @TYPE_MOUVEMENT = 0

-- Initialisation des variables
	SET @v_codeRetour=@CODE_OK

	-- Mise à jour de la tâche associée
	update TACHE set TAC_IdEtat = @ID_ETAT_ATTENTE, TAC_DscEtat = @v_relance
		where (TAC_IdMission = @v_mis_idmission)and(TAC_IdOrdre = @v_ord_idordre)
	if (@@ERROR <> 0)
		set @v_codeRetour=@CODE_KO_SQL
	if (@v_codeRetour = @CODE_OK)
	begin
		-- vérification si il s'agit de la dernière tâche stoppée associée à l'ordre  
		-- si c'est la cas l'ordre peut alors être relancé 
		if not exists (select 1 from TACHE where (TAC_IdEtat=@ID_ETAT_STOP)and(TAC_IdOrdre=@v_ord_idordre))
		begin
			-- Toutes les tâches ont été relancées
			-- vérification si les tâches de l'ordre ont toutes la même base  
			IF (SELECT COUNT(DISTINCT TAC_IDADRBASE) FROM TACHE WHERE TAC_IDORDRE = @v_ord_idordre) > 1
			BEGIN
				-- au moins 2 tâches n'ont pas la même base => Passage en revue de toutes les tâches de l'ordre
				-- et création de nouveaux ordres pour les tâches dont la base est différente de la base de l'ordre
				-- par défaut la base de l'ordre correspond à la base de la 1ère tâche de la liste 
				declare c_SelectTacheOrdre CURSOR LOCAL for
					select TAC_IdMission,TAC_Position_TACHE,TAC_IdAdrSys,TAC_IdAdrBase,ORD_Position,ORD_IdAgv 
					from TACHE,ORDRE_AGV
					where (TAC_IdOrdre=ORD_IdOrdre)and(TAC_IdOrdre=@v_ord_idordre)
				-- ouverture du curseur                
				open c_SelectTacheOrdre
				fetch next from c_SelectTacheOrdre INTO @v_mis_idmission,@v_positionTache,@v_adrSys,@v_adrBase,@v_positionOrdre,@v_idAgv
				set @v_isFirstTache = 1
				set @v_adrSysOrdre = 0
				set @v_adrBaseOrdre = 0
				while (@@FETCH_STATUS = 0)
				begin
					if (@v_isFirstTache = 1)
					begin
						set @v_adrSysOrdre = @v_adrSys
						set @v_adrBaseOrdre = @v_adrBase
						set @v_isFirstTache = 0
					end
					else if @v_adrBase <> @v_adrBaseOrdre
					begin
						set @v_positionOrdreSuiv = @v_positionOrdre + 1
						exec @v_codeRetour = SPV_CREATEORDRE @v_positionOrdreSuiv,@v_idAgv,@v_mis_idmission,@v_positionTache
						if (@v_codeRetour <> @CODE_OK)
							BREAK
					end
					fetch next from c_SelectTacheOrdre INTO @v_mis_idmission,@v_positionTache,@v_adrSys,@v_adrBase,@v_positionOrdre,@v_idAgv
				end
				-- fermeture du curseur 
				close c_SelectTacheOrdre
				deallocate c_SelectTacheOrdre          
			end
			-- Mise à jour de l'état de l'ordre Agv à relancer
			if (@v_codeRetour = @CODE_OK)
			begin
				UPDATE ORDRE_AGV SET ORD_IDETAT = @ID_ETAT_ATTENTE, ORD_DSCETAT = @v_relance, ORD_TYPE = @TYPE_MOUVEMENT
					WHERE ORD_IDORDRE = @v_ord_idordre
				if @@ERROR <> 0
					set @v_codeRetour=@CODE_KO_SQL
			end
		end
		else
		begin
			-- l'ordre ne peut pas être relancé
			set @v_codeRetour = @CODE_KO
		end
	end
	IF ((@v_relance = @DESC_RELANCE_MISSION AND @v_codeRetour = @CODE_OK) OR (@v_relance = @DESC_RELANCE_INTERNE))
	BEGIN
		IF EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE
			WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ID_ETAT_STOP AND TAC_IDORDRE = ORD_IDORDRE
			AND TAC_IDETAT <> @ID_ETAT_ATTENTE AND ((@v_relance = @DESC_RELANCE_MISSION AND TAC_DSCETAT = @DESC_REVISION)
			OR (@v_relance = @DESC_RELANCE_INTERNE)))
		BEGIN
			SELECT TOP 1 @v_mis_idmission = TAC_IDMISSION, @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV, TACHE
				WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ID_ETAT_STOP AND TAC_IDORDRE = ORD_IDORDRE
				AND TAC_IDETAT <> @ID_ETAT_ATTENTE AND ((@v_relance = @DESC_RELANCE_MISSION AND TAC_DSCETAT = @DESC_REVISION)
				OR (@v_relance = @DESC_RELANCE_INTERNE)) ORDER BY ORD_POSITION
			EXEC @v_codeRetour = SPV_RELANCEORDRE @v_iag_idagv, @v_ord_idordre, @v_mis_idmission, @DESC_RELANCE_INTERNE
			IF @v_codeRetour = @CODE_KO
				SELECT @v_codeRetour = @CODE_OK
		END
	END
	return @v_codeRetour


