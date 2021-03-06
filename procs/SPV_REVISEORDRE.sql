SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_REVISEORDRE
-- Paramètre d'entrée	: @v_idOrdre : Identifiant de l'ordre à réviser
--			  @v_iag_idagv : Identifiant de l'Agv
--			  @v_Position_Ordre : Position de l'ordre à réviser
--			  @v_interruption : Spécifie si l'activité de l'agv est interrompue
--			  ou non par un incident sur un ordre précédent
--			    - 1 : L'activité agv est interrompue 
--			    - 0 : L'activité agv n'est pas interrompue
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : La révision s'est exécutée correctement
--			    - @CODE_KO_SQL : Une erreur s'est produite lors de la révision
-- Descriptif		: Cette procédure révise un ordre Agv: C'est à dire contrôle
--			  s'il doit être conservé ou non
--			  Un ordre est considéré comme valide s'il est associé à une charge 
--			  présente sur l'Agv: Il est automatiquement mis dans l'état
--			  stoppé (interruption provisoire lié à l'interruption d'un ordre précédent)
--			  Dans les autres cas, on considère qu'il n'est pas valide et on le
--			  supprime.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_REVISEORDRE]
	@v_idOrdre integer,
	@v_iag_idagv tinyint,
	@v_position_Ordre integer,
	@v_interruption bit
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_retour int,
	@v_idMission integer,
	@v_position_tache tinyint,
	@v_tac_idtache int,
	@v_tac_idetattache tinyint,
	@v_chg_idcharge int,
	@v_mis_idtypemission tinyint,
	@v_mis_idetatmission tinyint,
	@v_position_OrdreSuiv integer,
	@v_idOrdreSuiv integer,
	@v_chargeSurAgv bit,
	@v_typeMag tinyint,
	@v_mag smallint,
	@v_newEtatOrdre tinyint
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_REVISION tinyint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_TRANSFERT_CHARGE tinyint,
	@TYPE_BATTERIE tinyint,
	@TYPE_MOUVEMENT tinyint,
	@TYPE_MAINTENANCE tinyint

-- Déclaration des constantes de types de magasin
DECLARE
	@TYPE_AGV tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_SUSPENDU = 4
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @TYPE_TRANSFERT_CHARGE = 1
	SET @TYPE_BATTERIE = 2
	SET @TYPE_MOUVEMENT = 3
	SET @TYPE_MAINTENANCE = 4
	SET @TYPE_AGV = 1
	SET @DESC_REVISION = 7

-- Initialisation des variables
	SET @v_retour = @CODE_OK

	------------------------------------------------------------------------------------
	--              TRAITEMENT DES TACHES DE L'ORDRE A REVISER
	------------------------------------------------------------------------------------
	DECLARE c_SelectTache CURSOR LOCAL FOR SELECT TAC_IDTACHE, TAC_IDETAT, TAC_IdMission, TAC_POSITION_TACHE, MIS_IdCharge, MIS_TypeMission, MIS_IDETAT
		FROM TACHE INNER JOIN MISSION ON TAC_IdMission = MIS_IdMission
		WHERE TAC_IdOrdre = @v_idOrdre
	OPEN c_SelectTache
	fetch next from  c_SelectTache INTO @v_tac_idtache, @v_tac_idetattache, @v_idMission, @v_position_tache, @v_chg_idcharge, @v_mis_idtypemission, @v_mis_idetatmission
	while (@@FETCH_STATUS = 0)
	begin
		IF ((@v_mis_idtypemission = @TYPE_MOUVEMENT) OR (@v_mis_idtypemission = @TYPE_BATTERIE))
		BEGIN
			UPDATE TACHE SET TAC_IdEtat = @ETAT_ANNULE, TAC_DscEtat = @DESC_REVISION, TAC_IdOrdre = NULL
				WHERE TAC_IDTACHE = @v_tac_idtache
			IF @@ERROR <> 0
			BEGIN
				SET @v_retour = @CODE_KO_SQL
				BREAK
			END
		END
		ELSE IF ((@v_mis_idtypemission = @TYPE_MAINTENANCE) OR (@v_mis_idtypemission = @TYPE_TRANSFERT_CHARGE AND (@v_chg_idcharge IS NULL OR NOT EXISTS (SELECT 1 FROM CHARGE
			LEFT OUTER JOIN ADRESSE ON ADR_SYSTEME = CHG_ADR_KEYSYS AND ADR_BASE = CHG_ADR_KEYBASE
			AND ADR_SOUSBASE = CHG_ADR_KEYSSBASE LEFT OUTER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
			WHERE CHG_ID = @v_chg_idcharge AND BAS_TYPE_MAGASIN = @TYPE_AGV AND BAS_MAGASIN = @v_iag_idagv))))
		BEGIN
			-- Dans le cas d'une tâche qui repasse en attente, les autres tâches terminées ou annulées de la mission
			-- repasse également en attente
	  		IF @v_tac_idetattache = @ETAT_ENATTENTE
				UPDATE TACHE SET TAC_IDETAT = @v_tac_idetattache WHERE TAC_IDTACHE <> @v_tac_idtache AND TAC_IDMISSION = @v_idMission
					AND TAC_IDETAT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			IF @@ERROR = 0
			BEGIN
				UPDATE TACHE SET TAC_IdEtat = CASE @v_mis_idetatmission WHEN @ETAT_SUSPENDU THEN @ETAT_SUSPENDU ELSE TAC_IdEtat END, TAC_DscEtat = CASE @v_mis_idetatmission WHEN @ETAT_SUSPENDU THEN @DESC_REVISION ELSE TAC_DscEtat END,
					TAC_IdOrdre = NULL WHERE TAC_IDTACHE = @v_tac_idtache
				IF @@ERROR <> 0
				BEGIN
					SET @v_retour = @CODE_KO_SQL
					BREAK
				END
				ELSE IF (@v_tac_idetattache = @ETAT_ENATTENTE AND @v_position_tache = (SELECT MIN(TAC_POSITION_TACHE) FROM TACHE WHERE TAC_IDMISSION = @v_idMission AND TAC_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)))
					EXEC @v_retour = SPV_DESAFFINEEXECUTION @v_idMission
			END
			ELSE
			BEGIN
				SET @v_retour = @CODE_KO_SQL
				BREAK
			END
		END
		ELSE IF @v_mis_idtypemission = @TYPE_TRANSFERT_CHARGE
		BEGIN
			IF @v_interruption = 1
			BEGIN
				UPDATE TACHE SET TAC_IdEtat = @ETAT_STOPPE, TAC_DscEtat = @DESC_REVISION
					WHERE CURRENT OF c_SelectTache
				IF @@ERROR <> 0
				BEGIN
					SET @v_retour = @CODE_KO_SQL
					BREAK
				END
			END
		END
		-- passage à la tâche suivante
		FETCH NEXT FROM c_SelectTache INTO @v_tac_idtache, @v_tac_idetattache, @v_idMission, @v_position_tache, @v_chg_idcharge, @v_mis_idtypemission, @v_mis_idetatmission
	end
	-- fermeture du curseur
	close c_SelectTache
	deallocate c_SelectTache
	-- récupération de l'ordre suivant
	select TOP 1 @v_idOrdreSuiv=ORD_IdOrdre,@v_position_OrdreSuiv=ORD_Position from ORDRE_AGV
		where (ORD_Position>@v_position_Ordre)and(ORD_IdAgv=@v_iag_idagv)
		AND ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
		order by ORD_Position
	------------------------------------------------------------------------------------
	--              TRAITEMENT DE L'ORDRE A REVISER
	------------------------------------------------------------------------------------
	if @v_retour=@CODE_OK
	begin
		set @v_newEtatOrdre = NULL 
		if not exists (select 1 from TACHE where TAC_IdOrdre=@v_idOrdre)
		begin
			-- l'ordre n'a plus de tâches rattachées, on le passe dans l'état annulé 
			set @v_newEtatOrdre = @ETAT_ANNULE
		end
		else
		begin
			-- si il a au moins une tâche rattachée, si il y a interruption de l'activité agv
			-- on passe l'ordre dans l'état stoppé
			if (@v_interruption = 1)
				set @v_newEtatOrdre = @ETAT_STOPPE
		end 
		if (@v_newEtatOrdre is not NULL)
		begin
			UPDATE ORDRE_AGV SET ORD_IDETAT = @v_newEtatOrdre, ORD_DSCETAT = @DESC_REVISION
				WHERE ORD_IDORDRE = @v_idOrdre
			if @@ERROR <> 0
				set @v_retour=@CODE_KO_SQL
		end
	end 
	------------------------------------------------------------------------------------
	--              TRAITEMENT DES ORDRES SUIVANTS
	------------------------------------------------------------------------------------
	IF @v_retour = @CODE_OK AND @v_idOrdreSuiv IS NOT NULL
		exec @v_retour = SPV_REVISEORDRE @v_idOrdreSuiv, @v_iag_idagv, @v_position_OrdreSuiv, @v_interruption
	return @v_retour


